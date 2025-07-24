import json
import logging
from typing import List, Dict, Any, Optional
import asyncio
from anthropic import Anthropic

from .base import AIProvider, FlashcardData, AIGenerationRequest, AIResponse

logger = logging.getLogger(__name__)


class ClaudeProvider(AIProvider):
    """Anthropic Claude AI provider for flashcard generation"""

    def __init__(self, api_key: str, model: str = "claude-3-5-sonnet-20241022"):
        super().__init__(api_key, model)
        self.client = Anthropic(api_key=api_key)
        self._model = model

    @property
    def name(self) -> str:
        return "Claude"

    @property
    def max_tokens(self) -> int:
        return 4096  # Claude's standard max tokens for responses

    def get_provider_info(self) -> Dict[str, str]:
        return {
            "name": self.name,
            "model": self._model,
            "provider": "Anthropic",
            "max_tokens": str(self.max_tokens)
        }

    async def generate_flashcards(self, request: AIGenerationRequest) -> AIResponse:
        """Generate flashcards using Claude"""

        prompt = self._build_flashcard_prompt(request)

        try:
            # Run the sync call in a thread pool to make it async
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.client.messages.create(
                    model=self._model,
                    max_tokens=self.max_tokens,
                    temperature=0.7,
                    messages=[{"role": "user", "content": prompt}]
                )
            )

            cards_data = self._parse_flashcard_response(response.content[0].text, request)

            metadata = {
                "model": self._model,
                "provider": self.name,
                "tokens_used": response.usage.input_tokens + response.usage.output_tokens,
                "input_tokens": response.usage.input_tokens,
                "output_tokens": response.usage.output_tokens,
                "generation_time": None,  # Claude doesn't provide this directly
                "prompt_length": len(prompt)
            }

            return AIResponse(cards=cards_data, metadata=metadata)

        except Exception as e:
            logger.error(f"Claude API error: {str(e)}")
            # Fallback to ensure we don't break the app
            return self._create_fallback_response(request)

    async def generate_similar_card(self, base_card: FlashcardData, topic: str) -> FlashcardData:
        """Generate a similar card based on an existing card"""

        prompt = f"""Generate ONE similar flashcard based on this example:

**Original Card:**
Question: {base_card.question}
Answer: {base_card.answer}
Explanation: {base_card.explanation}
Topic: {topic}

Create a NEW flashcard that:
1. Covers a related concept in the same topic
2. Has similar complexity level
3. Uses a different angle or approach
4. Is NOT a variation of the same question

Respond with ONLY this JSON format:
{{
    "question": "Your new question here",
    "answer": "Detailed answer",
    "explanation": "Why this is important or how it relates",
    "confidence": 0.85
}}"""

        try:
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.client.messages.create(
                    model=self._model,
                    max_tokens=1000,
                    temperature=0.8,
                    messages=[{"role": "user", "content": prompt}]
                )
            )

            response_text = response.content[0].text.strip()

            # Extract JSON from response
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                response_text = response_text[json_start:json_end].strip()
            elif "{" in response_text:
                # Find the JSON object
                start = response_text.find("{")
                end = response_text.rfind("}") + 1
                response_text = response_text[start:end]

            card_data = json.loads(response_text)

            return FlashcardData(
                question=card_data["question"],
                answer=card_data["answer"],
                explanation=card_data["explanation"],
                difficulty=base_card.difficulty,
                tags=base_card.tags + ["ai-similar"],
                confidence=card_data.get("confidence", 0.85)
            )

        except Exception as e:
            logger.error(f"Error generating similar card: {str(e)}")
            # Return a basic similar card as fallback
            return FlashcardData(
                question=f"Related concept to {topic}: What is another important aspect?",
                answer=f"This is a related concept in {topic} that builds on similar principles.",
                explanation="This card was generated as a fallback when AI generation failed.",
                difficulty=base_card.difficulty,
                tags=base_card.tags + ["fallback"],
                confidence=0.6
            )

    async def generate_answer(self, question: str, context: str = "", deck_topic: str = "") -> Dict[str, Any]:
        """Generate an AI answer for a given question"""

        print(f"Generating answer for question: {question}")

        prompt = f"""Answer this question with accuracy and depth:

**Question:** {question}

**Context:** {context if context else "General knowledge"}
**Subject Area:** {deck_topic if deck_topic else "General"}

Provide a comprehensive answer that:
1. Directly answers the question
2. Gives practical, useful information
3. Includes relevant details an expert would know
4. Avoids generic or vague responses

Keep your answer focused and informative.
Just a couple of words, it needs to be SUPER concise and to the point. Do not repeat the question in your answer OR ELSE.
Do not mention the subject area in your answer EVER!!!."""

        try:
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.client.messages.create(
                    model=self._model,
                    max_tokens=800,
                    temperature=0.6,
                    messages=[{"role": "user", "content": prompt}]
                )
            )

            answer = response.content[0].text.strip()
            print(f"Answer: {answer}")

            return {
                "answer": answer,
                "explanation": f"Generated using {self.name} for {deck_topic or 'general knowledge'}",
                "confidence": 0.88,
                "sources": [],
                "suggested_tags": [deck_topic.lower() if deck_topic else "general", "ai-generated"]
            }

        except Exception as e:
            logger.error(f"Error generating answer: {str(e)}")
            return {
                "answer": "I apologize, but I'm unable to generate an answer at this time due to a technical issue.",
                "explanation": "This is a fallback response when AI generation fails.",
                "confidence": 0.1,
                "sources": [],
                "suggested_tags": ["error", "fallback"]
            }

    def _build_flashcard_prompt(self, request: AIGenerationRequest) -> str:
        """Build optimized prompt for flashcard generation"""

        difficulty_guidance = {
            "easy": "basic concepts, definitions, and fundamental facts",
            "medium": "practical applications, relationships between concepts, and analytical thinking",
            "hard": "complex analysis, synthesis of multiple concepts, and expert-level insights"
        }

        # Detect topic type for specialized prompts
        topic_lower = request.topic.lower()

        if any(tech in topic_lower for tech in ["programming", "javascript", "typescript", "python", "coding", "software"]):
            prompt_type = "programming"
        elif any(culinary in topic_lower for culinary in ["cooking", "culinary", "chef", "food", "baking"]):
            prompt_type = "culinary"
        elif any(strategy in topic_lower for strategy in ["chess", "strategy", "tactics"]):
            prompt_type = "strategy"
        else:
            prompt_type = "general"

        base_prompt = f"""Generate {request.number_of_cards} high-quality flashcards about {request.topic}.

**Requirements:**
- Difficulty: {request.difficulty} ({difficulty_guidance.get(request.difficulty, "appropriate level")})
- Focus on {self._get_topic_focus(prompt_type, request.topic)}
- Each card should test genuine understanding, not just memorization
- Questions should be specific and answerable
- Answers should be accurate and practical
- NO generic questions like "What is {request.topic}?" or "What are the benefits of..."

**Card Format:**
Return ONLY a JSON array with this exact structure:
[
    {{
        "question": "Specific, testable question",
        "answer": "Clear, accurate answer (2-4 sentences)",
        "explanation": "Why this matters or how it connects to broader concepts",
        "difficulty": "{request.difficulty}",
        "tags": ["relevant", "topic", "tags"],
        "confidence": 0.85
    }}
]

{self._get_topic_specific_guidance(prompt_type, request.topic)}

Generate exactly {request.number_of_cards} cards that an expert in {request.topic} would find valuable."""

        return base_prompt

    def _get_topic_focus(self, prompt_type: str, topic: str) -> str:
        """Get focus guidance based on topic type"""
        focus_map = {
            "programming": "practical coding concepts, syntax, best practices, and real-world applications",
            "culinary": "techniques, temperatures, timing, ingredients, and professional kitchen knowledge",
            "strategy": "tactics, principles, decision-making, and strategic thinking",
            "general": "practical knowledge, expert insights, and actionable information"
        }
        return focus_map.get(prompt_type, focus_map["general"])

    def _get_topic_specific_guidance(self, prompt_type: str, topic: str) -> str:
        """Get topic-specific prompt guidance"""

        if prompt_type == "programming":
            return f"""
**Programming Focus for {topic}:**
- Syntax and practical code examples
- Common pitfalls and debugging
- Best practices and design patterns
- Performance considerations
- Real-world usage scenarios"""

        elif prompt_type == "culinary":
            return f"""
**Culinary Focus for {topic}:**
- Specific temperatures, times, and measurements
- Professional techniques and methods
- Food safety and quality indicators
- Equipment usage and maintenance
- Flavor development and presentation"""

        elif prompt_type == "strategy":
            return f"""
**Strategy Focus for {topic}:**
- Tactical patterns and principles
- Decision-making frameworks
- Position evaluation criteria
- Common mistakes and how to avoid them
- Advanced concepts for improvement"""

        else:
            return f"""
**Expert Knowledge Focus for {topic}:**
- Professional insights and industry standards
- Practical applications and real-world scenarios
- Quality indicators and best practices
- Common misconceptions and expert corrections
- Advanced concepts that separate novices from experts"""

    def _parse_flashcard_response(self, response_text: str, request: AIGenerationRequest) -> List[FlashcardData]:
        """Parse Claude's response into FlashcardData objects"""

        try:
            # Clean up the response text
            response_text = response_text.strip()

            # Extract JSON array from response
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                response_text = response_text[json_start:json_end].strip()
            elif "[" in response_text and "]" in response_text:
                # Find the JSON array
                start = response_text.find("[")
                end = response_text.rfind("]") + 1
                response_text = response_text[start:end]

            cards_json = json.loads(response_text)

            cards = []
            for card_data in cards_json:
                card = FlashcardData(
                    question=card_data.get("question", ""),
                    answer=card_data.get("answer", ""),
                    explanation=card_data.get("explanation", ""),
                    difficulty=card_data.get("difficulty", request.difficulty),
                    tags=card_data.get("tags", [request.topic.lower(), "ai-generated"]),
                    confidence=card_data.get("confidence", 0.85)
                )
                cards.append(card)

            return cards

        except Exception as e:
            logger.error(f"Error parsing Claude response: {str(e)}")
            logger.debug(f"Raw response: {response_text}")
            return self._create_fallback_cards(request)

    def _create_fallback_response(self, request: AIGenerationRequest) -> AIResponse:
        """Create fallback response when AI fails"""
        cards = self._create_fallback_cards(request)
        metadata = {
            "model": "fallback",
            "provider": "fallback",
            "tokens_used": 0,
            "error": "AI generation failed, using fallback"
        }
        return AIResponse(cards=cards, metadata=metadata)

    def _create_fallback_cards(self, request: AIGenerationRequest) -> List[FlashcardData]:
        """Create basic fallback cards when AI fails"""
        return [
            FlashcardData(
                question=f"What is an important concept in {request.topic}?",
                answer=f"This is a fundamental concept in {request.topic} that requires further study.",
                explanation="This card was generated as a fallback when AI generation failed.",
                difficulty=request.difficulty,
                tags=[request.topic.lower(), "fallback"],
                confidence=0.3
            )
            for _ in range(min(request.number_of_cards, 3))  # Limit fallback cards
        ]