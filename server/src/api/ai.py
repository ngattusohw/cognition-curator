import random
import time

from flask import Blueprint, jsonify, request

ai_bp = Blueprint("ai", __name__)

# Sample knowledge base for different topics
TOPIC_KNOWLEDGE = {
    "javascript": {
        "domain": "programming",
        "cards": [
            {
                "question": "What is JavaScript?",
                "answer": "JavaScript is a versatile, high-level programming language primarily used for creating interactive web applications and dynamic content on websites.",
                "explanation": "JavaScript is interpreted at runtime and supports both object-oriented and functional programming paradigms.",
                "difficulty": "easy",
                "tags": ["basics", "definition"],
            },
            {
                "question": "What are JavaScript variables?",
                "answer": "Variables in JavaScript are containers that store data values. They can be declared using var, let, or const keywords.",
                "explanation": "let and const are block-scoped, while var is function-scoped. const creates immutable references.",
                "difficulty": "easy",
                "tags": ["variables", "basics"],
            },
            {
                "question": "What is the difference between == and === in JavaScript?",
                "answer": "== performs type coercion and compares values, while === compares both value and type without coercion.",
                "explanation": "=== is generally preferred as it's more predictable and prevents unexpected type conversions.",
                "difficulty": "medium",
                "tags": ["operators", "comparison"],
            },
            {
                "question": "What are JavaScript functions?",
                "answer": "Functions are reusable blocks of code that perform specific tasks. They can be declared using function declarations, expressions, or arrow functions.",
                "explanation": "Functions are first-class objects in JavaScript, meaning they can be assigned to variables, passed as arguments, and returned from other functions.",
                "difficulty": "easy",
                "tags": ["functions", "basics"],
            },
            {
                "question": "What is hoisting in JavaScript?",
                "answer": "Hoisting is JavaScript's behavior of moving variable and function declarations to the top of their scope during compilation.",
                "explanation": "Only declarations are hoisted, not initializations. let and const are hoisted but not initialized.",
                "difficulty": "medium",
                "tags": ["hoisting", "scope"],
            },
            {
                "question": "What are JavaScript arrays?",
                "answer": "Arrays are ordered collections of elements that can store multiple values of any type. They are zero-indexed and have dynamic length.",
                "explanation": "Arrays in JavaScript are actually objects with numeric keys and special length property.",
                "difficulty": "easy",
                "tags": ["arrays", "data-structures"],
            },
            {
                "question": "What is the DOM in JavaScript?",
                "answer": "The Document Object Model (DOM) is a programming interface that represents HTML documents as a tree structure that JavaScript can manipulate.",
                "explanation": "The DOM allows JavaScript to dynamically change content, structure, and styling of web pages.",
                "difficulty": "medium",
                "tags": ["dom", "web"],
            },
            {
                "question": "What are JavaScript events?",
                "answer": "Events are actions that occur in the browser, such as clicks, key presses, or page loads. JavaScript can listen for and respond to these events.",
                "explanation": "Event handling allows creating interactive web applications that respond to user actions.",
                "difficulty": "medium",
                "tags": ["events", "interactivity"],
            },
            {
                "question": "What is closure in JavaScript?",
                "answer": "A closure is a function that retains access to variables from its outer (enclosing) scope even after the outer function has finished executing.",
                "explanation": "Closures enable data privacy and are fundamental to many JavaScript patterns and frameworks.",
                "difficulty": "hard",
                "tags": ["closures", "advanced"],
            },
            {
                "question": "What are JavaScript objects?",
                "answer": "Objects are collections of key-value pairs where keys are strings (or Symbols) and values can be any data type including functions.",
                "explanation": "Objects are the foundation of JavaScript and most built-in types are actually objects.",
                "difficulty": "easy",
                "tags": ["objects", "basics"],
            },
        ],
    },
    "typescript": {
        "domain": "programming",
        "cards": [
            {
                "question": "What is TypeScript?",
                "answer": "TypeScript is a strongly typed programming language that builds on JavaScript by adding static type definitions.",
                "explanation": "TypeScript compiles to plain JavaScript and runs anywhere JavaScript runs: browsers, Node.js, and any JavaScript engine.",
                "difficulty": "easy",
                "tags": ["basics", "definition"]
            },
            {
                "question": "What is the difference between 'any' and 'unknown' types?",
                "answer": "'any' disables all type checking, while 'unknown' is a type-safe alternative that requires type assertion or narrowing before use.",
                "explanation": "Use 'unknown' instead of 'any' when you don't know the type, as it forces you to perform type checks.",
                "difficulty": "medium",
                "tags": ["types", "safety"]
            },
            {
                "question": "What is an interface in TypeScript?",
                "answer": "An interface defines the shape of an object, specifying what properties and methods it should have.",
                "explanation": "Interfaces are a powerful way to define contracts within your code and ensure type safety.",
                "difficulty": "easy",
                "tags": ["interface", "types"]
            },
            {
                "question": "What is the difference between 'interface' and 'type' alias?",
                "answer": "Interfaces can be extended and merged, while type aliases are more flexible for unions, primitives, and computed types.",
                "explanation": "Use interfaces for object shapes that might be extended, and type aliases for unions or computed types.",
                "difficulty": "medium",
                "tags": ["interface", "type", "differences"]
            },
            {
                "question": "What are TypeScript generics?",
                "answer": "Generics allow you to create reusable components that work with multiple types while preserving type information.",
                "explanation": "Generics provide a way to make components work over a variety of types rather than a single one.",
                "difficulty": "hard",
                "tags": ["generics", "reusability"]
            },
            {
                "question": "What is type assertion in TypeScript?",
                "answer": "Type assertion is a way to tell the compiler to treat a value as a specific type using 'as' syntax or angle brackets.",
                "explanation": "Use type assertions when you know more about the type than TypeScript can infer.",
                "difficulty": "medium",
                "tags": ["assertion", "casting"]
            },
            {
                "question": "What are union types in TypeScript?",
                "answer": "Union types allow a value to be one of several types, defined using the pipe (|) operator.",
                "explanation": "Union types are useful when a value can legitimately be one of several types.",
                "difficulty": "medium",
                "tags": ["union", "types"]
            },
            {
                "question": "What is the 'never' type used for?",
                "answer": "The 'never' type represents values that never occur, such as functions that always throw or have infinite loops.",
                "explanation": "The 'never' type is useful for exhaustive type checking and representing impossible states.",
                "difficulty": "hard",
                "tags": ["never", "type-safety"]
            },
            {
                "question": "What are access modifiers in TypeScript classes?",
                "answer": "public (default), private, protected, and readonly modifiers control visibility and mutability of class members.",
                "explanation": "Access modifiers help enforce encapsulation and design contracts in object-oriented programming.",
                "difficulty": "medium",
                "tags": ["classes", "modifiers", "oop"]
            },
            {
                "question": "What is the difference between '==' and '===' in TypeScript?",
                "answer": "=== checks for strict equality (value and type), while == performs type coercion before comparison.",
                "explanation": "Always use === for predictable comparisons and better type safety.",
                "difficulty": "easy",
                "tags": ["operators", "comparison"]
            },
            {
                "question": "What are TypeScript decorators?",
                "answer": "Decorators are special declarations that can be attached to classes, methods, properties, or parameters to modify their behavior.",
                "explanation": "Decorators provide a way to add metadata and modify classes and their members at design time.",
                "difficulty": "hard",
                "tags": ["decorators", "metadata"]
            },
            {
                "question": "What is a tuple in TypeScript?",
                "answer": "A tuple is an array with a fixed number of elements of specific types in a specific order.",
                "explanation": "Tuples are useful when you want to represent a fixed collection of heterogeneous values.",
                "difficulty": "medium",
                "tags": ["tuple", "array", "types"]
            }
        ]
    },
    "fuel system": {
        "domain": "automotive",
        "cards": [
            {
                "question": "What is the primary function of a fuel system?",
                "answer": "To store, deliver, and filter fuel from the tank to the engine combustion chambers at the correct pressure and flow rate.",
                "explanation": "The fuel system ensures the engine receives clean fuel at optimal pressure for efficient combustion.",
                "difficulty": "easy",
                "tags": ["basics", "function"],
            },
            {
                "question": "What are the main components of a fuel system?",
                "answer": "Fuel tank, fuel pump, fuel filter, fuel injectors, fuel pressure regulator, and fuel lines.",
                "explanation": "Each component plays a specific role in fuel storage, delivery, and injection.",
                "difficulty": "medium",
                "tags": ["components", "system"],
            },
            {
                "question": "How does a fuel pump work?",
                "answer": "Electric fuel pumps use an impeller or gear mechanism to create pressure, drawing fuel from the tank and pushing it through the fuel lines to the engine.",
                "explanation": "Modern vehicles typically use electric fuel pumps located inside the fuel tank for better performance and safety.",
                "difficulty": "medium",
                "tags": ["pump", "operation"],
            },
            {
                "question": "What is the purpose of a fuel filter?",
                "answer": "To remove contaminants, dirt, and debris from fuel before it reaches the engine, protecting fuel injectors and combustion chambers.",
                "explanation": "Clean fuel is essential for proper engine operation and longevity of fuel system components.",
                "difficulty": "easy",
                "tags": ["filter", "maintenance"],
            },
            {
                "question": "What is fuel pressure regulation?",
                "answer": "The process of maintaining consistent fuel pressure throughout the system using a fuel pressure regulator, typically 40-60 PSI for most vehicles.",
                "explanation": "Proper fuel pressure ensures optimal fuel injection timing and engine performance.",
                "difficulty": "hard",
                "tags": ["pressure", "regulation"],
            },
            {
                "question": "How do fuel injectors work?",
                "answer": "Electronically controlled valves that spray precisely metered amounts of fuel into the engine's intake manifold or combustion chamber.",
                "explanation": "Fuel injectors replaced carburetors for more precise fuel delivery and better emissions control.",
                "difficulty": "medium",
                "tags": ["injectors", "precision"],
            },
            {
                "question": "What are common signs of fuel system problems?",
                "answer": "Engine hesitation, poor acceleration, rough idling, decreased fuel economy, engine stalling, and difficulty starting.",
                "explanation": "These symptoms often indicate issues with fuel delivery, pressure, or contamination.",
                "difficulty": "easy",
                "tags": ["troubleshooting", "symptoms"],
            },
            {
                "question": "What is the difference between port and direct injection?",
                "answer": "Port injection sprays fuel into the intake manifold, while direct injection sprays fuel directly into the combustion chamber.",
                "explanation": "Direct injection provides better fuel economy and power but requires higher pressure and more precise timing.",
                "difficulty": "hard",
                "tags": ["injection", "technology"],
            },
            {
                "question": "How often should fuel filters be replaced?",
                "answer": "Typically every 20,000-40,000 miles, but varies by vehicle and driving conditions. Check manufacturer recommendations.",
                "explanation": "Regular fuel filter replacement prevents clogging and maintains proper fuel flow to the engine.",
                "difficulty": "easy",
                "tags": ["maintenance", "intervals"],
            },
            {
                "question": "What is a fuel rail?",
                "answer": "A metal tube that distributes pressurized fuel to multiple fuel injectors, ensuring equal fuel pressure and distribution.",
                "explanation": "The fuel rail acts as a manifold system for fuel delivery in multi-cylinder engines.",
                "difficulty": "medium",
                "tags": ["rail", "distribution"],
            },
            {
                "question": "What causes fuel pump failure?",
                "answer": "Running on low fuel (overheating), contaminated fuel, electrical issues, wear over time, and clogged fuel filters.",
                "explanation": "Maintaining adequate fuel levels and clean fuel helps extend fuel pump life.",
                "difficulty": "medium",
                "tags": ["failure", "causes"],
            },
            {
                "question": "What is a returnless fuel system?",
                "answer": "A modern fuel system design that eliminates the fuel return line by using a pressure regulator inside the fuel tank.",
                "explanation": "Returnless systems reduce complexity, emissions, and fuel temperature while improving efficiency.",
                "difficulty": "hard",
                "tags": ["returnless", "modern"],
            },
            {
                "question": "How do you test fuel pressure?",
                "answer": "Connect a fuel pressure gauge to the fuel rail test port and compare readings to manufacturer specifications during various engine conditions.",
                "explanation": "Fuel pressure testing is essential for diagnosing fuel delivery problems and system performance.",
                "difficulty": "medium",
                "tags": ["testing", "diagnosis"],
            },
            {
                "question": "What is fuel trim?",
                "answer": "Engine computer adjustments to fuel delivery based on oxygen sensor feedback to maintain optimal air-fuel ratio.",
                "explanation": "Fuel trim values help diagnose fuel system efficiency and identify potential problems.",
                "difficulty": "hard",
                "tags": ["trim", "feedback"],
            },
            {
                "question": "What safety features are built into fuel systems?",
                "answer": "Fuel cutoff switches, vapor recovery systems, pressure relief valves, and rollover valves to prevent fuel leaks during accidents.",
                "explanation": "Safety features protect against fire hazards and environmental contamination in case of vehicle damage.",
                "difficulty": "medium",
                "tags": ["safety", "protection"],
            },
        ],
    },
    "spanish verbs": {
        "domain": "language",
        "cards": [
            {
                "question": "How do you conjugate 'hablar' (to speak) in present tense for 'yo'?",
                "answer": "Hablo",
                "explanation": "Regular -ar verbs drop the -ar and add -o for first person singular.",
                "difficulty": "easy",
                "tags": ["conjugation", "present", "regular"],
            },
            {
                "question": "What is the past participle of 'escribir' (to write)?",
                "answer": "Escrito",
                "explanation": "Escribir has an irregular past participle. Regular -ir verbs would end in -ido.",
                "difficulty": "medium",
                "tags": ["participle", "irregular"],
            },
        ],
    },
}


def generate_cards_for_topic(topic, num_cards=15, difficulty="medium"):
    """Generate flashcards for a given topic"""
    topic_lower = topic.lower()

    # Check if we have specific knowledge for this topic (flexible matching)
    matched_topic = None
    if topic_lower in TOPIC_KNOWLEDGE:
        matched_topic = topic_lower
    else:
        # Smart matching for programming topics and variations
        programming_mappings = {
            'javascript': ['js', 'javascript', 'java script'],
            'typescript': ['ts', 'typescript', 'type script'],
            'fuel system': ['fuel', 'automotive']
        }

        # Try exact programming topic matching first
        for known_topic, variations in programming_mappings.items():
            for variation in variations:
                if variation in topic_lower:
                    matched_topic = known_topic
                    break
            if matched_topic:
                break

        # If no programming match, try partial matching
        if not matched_topic:
            for known_topic in TOPIC_KNOWLEDGE.keys():
                if known_topic in topic_lower or topic_lower.startswith(known_topic):
                    matched_topic = known_topic
                    break

    if matched_topic:
        knowledge = TOPIC_KNOWLEDGE[matched_topic]
        available_cards = knowledge["cards"]

        # Filter by difficulty if specified
        if difficulty != "medium":
            filtered_cards = [
                card for card in available_cards if card["difficulty"] == difficulty
            ]
            if filtered_cards:
                available_cards = filtered_cards

        # Select cards (shuffle and take requested number)
        selected_cards = random.sample(
            available_cards, min(num_cards, len(available_cards))
        )

        # Add confidence scores
        for card in selected_cards:
            card["confidence"] = random.uniform(0.85, 0.98)

        return selected_cards

    # Generic fallback generation for unknown topics
    return generate_generic_cards(topic, num_cards, difficulty)


def generate_generic_cards(topic, num_cards, difficulty):
    """Generate intelligent cards for any topic"""

    # Clean up the topic name to extract the core technology
    clean_topic = extract_core_topic(topic)

    # Detect if this is a programming/tech topic
    if is_programming_topic(topic):
        return generate_programming_cards(clean_topic, num_cards, difficulty)
    else:
        return generate_general_topic_cards(topic, num_cards, difficulty)

def extract_core_topic(topic):
    """Extract the core technology from variations like 'TypeScript 101', 'React Basics', etc."""
    topic_lower = topic.lower()

    # Remove common course/level indicators
    removals = ['101', 'basics', 'fundamentals', 'intro', 'introduction', 'beginner', 'advanced', 'course']
    for removal in removals:
        topic_lower = topic_lower.replace(removal, '').strip()

    # Clean up extra spaces and return
    return ' '.join(topic_lower.split())

def is_programming_topic(topic):
    """Detect if a topic is related to programming/technology"""
    programming_keywords = [
        'javascript', 'typescript', 'python', 'java', 'react', 'vue', 'angular', 'node',
        'css', 'html', 'sql', 'mongodb', 'programming', 'coding', 'development',
        'framework', 'library', 'api', 'database', 'algorithm', 'data structure'
    ]

    topic_lower = topic.lower()
    return any(keyword in topic_lower for keyword in programming_keywords)

def generate_programming_cards(topic, num_cards, difficulty):
    """Generate programming-specific cards"""

    # Programming-focused question patterns
    question_patterns = [
        f"What is {topic}?",
        f"How do you declare variables in {topic}?",
        f"What are the key features of {topic}?",
        f"How do you handle errors in {topic}?",
        f"What are functions in {topic}?",
        f"How do you work with arrays in {topic}?",
        f"What are objects in {topic}?",
        f"How do you implement loops in {topic}?",
        f"What are the data types in {topic}?",
        f"How do you debug {topic} code?",
        f"What are best practices for {topic}?",
        f"How do you handle asynchronous operations in {topic}?",
        f"What are modules in {topic}?",
        f"How do you test {topic} applications?",
        f"What are common patterns in {topic}?",
    ]

    # Programming-focused answer patterns
    answer_patterns = [
        f"{topic} is a programming language/technology that provides developers with tools for building applications.",
        f"Variables in {topic} are declared using specific syntax and can store different types of data.",
        f"Key features of {topic} include type safety, modern syntax, and powerful development tools.",
        f"Error handling in {topic} typically involves try-catch blocks and proper exception management.",
        f"Functions in {topic} are reusable blocks of code that can accept parameters and return values.",
        f"Arrays in {topic} are ordered collections that can store multiple values and provide various methods for manipulation.",
        f"Objects in {topic} are complex data types that can contain properties and methods.",
        f"Loops in {topic} allow you to repeat code execution using for, while, or other iteration constructs.",
        f"Data types in {topic} include primitives like strings, numbers, booleans, and complex types like objects and arrays.",
        f"Debugging {topic} code involves using developer tools, console logging, and systematic problem-solving approaches.",
        f"Best practices for {topic} include writing clean code, following naming conventions, and proper code organization.",
        f"Asynchronous operations in {topic} are handled using callbacks, promises, or async/await patterns.",
        f"Modules in {topic} help organize code into reusable components and manage dependencies.",
        f"Testing {topic} applications involves unit tests, integration tests, and using appropriate testing frameworks.",
        f"Common patterns in {topic} include design patterns, architectural patterns, and coding conventions.",
    ]

    cards = []
    for i in range(min(num_cards, len(question_patterns))):
        card = {
            "question": question_patterns[i],
            "answer": answer_patterns[i],
            "explanation": f"This covers fundamental {topic} concepts that developers should understand.",
            "difficulty": difficulty,
            "tags": [topic.lower(), "programming", "generated"],
            "confidence": random.uniform(0.75, 0.9),
        }
        cards.append(card)

    return cards

def generate_general_topic_cards(topic, num_cards, difficulty):
    """Generate cards for non-programming topics"""

    question_patterns = [
        f"What is {topic}?",
        f"How does {topic} work?",
        f"Why is {topic} important?",
        f"What are the main characteristics of {topic}?",
        f"How is {topic} used in practice?",
        f"What are the benefits of {topic}?",
        f"What are the key principles of {topic}?",
        f"How do you implement {topic}?",
        f"What are best practices for {topic}?",
        f"What tools are used with {topic}?",
    ]

    answer_patterns = [
        f"{topic} is a concept that encompasses various important aspects of its field.",
        f"{topic} operates through a series of interconnected processes and mechanisms.",
        f"{topic} is important because it provides essential functionality and benefits.",
        f"The main characteristics of {topic} include its core features and properties.",
        f"{topic} is used in practice through various applications and implementations.",
        f"The benefits of {topic} include improved efficiency, effectiveness, and outcomes.",
        f"Key principles of {topic} include fundamental concepts and core methodologies.",
        f"To implement {topic}, you need to follow established procedures and best practices.",
        f"Best practices for {topic} include proper planning, execution, and maintenance.",
        f"Common tools used with {topic} include specialized software and equipment.",
    ]

    cards = []
    for i in range(min(num_cards, len(question_patterns))):
        card = {
            "question": question_patterns[i],
            "answer": answer_patterns[i],
            "explanation": f"This card covers important aspects of {topic} for general understanding.",
            "difficulty": difficulty,
            "tags": [topic.lower(), "generated", "overview"],
            "confidence": random.uniform(0.7, 0.85),
        }
        cards.append(card)

    return cards


@ai_bp.route("/generate-flashcards", methods=["POST"])
def generate_flashcards():
    """Generate flashcards based on a topic"""
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "No data provided"}), 400

        topic = data.get("topic", "").strip()
        if not topic:
            return jsonify({"error": "Topic is required"}), 400

        number_of_cards = data.get("number_of_cards", 15)
        difficulty = data.get("difficulty", "medium")
        focus = data.get("focus")
        card_type = data.get("card_type", "flashcard")

        # Validate inputs
        if number_of_cards < 1 or number_of_cards > 50:
            return jsonify({"error": "Number of cards must be between 1 and 50"}), 400

        if difficulty not in ["easy", "medium", "hard"]:
            return jsonify({"error": "Difficulty must be easy, medium, or hard"}), 400

        # Simulate processing time for realistic feel
        time.sleep(random.uniform(1.0, 2.5))

        # Generate cards
        cards = generate_cards_for_topic(topic, number_of_cards, difficulty)

        response = {
            "cards": cards,
            "topic": topic,
            "total_generated": len(cards),
            "difficulty": difficulty,
            "focus": focus,
            "generation_time": random.uniform(1.2, 3.5),
            "model_version": "gpt-4-preview",
            "confidence_avg": sum(card["confidence"] for card in cards) / len(cards)
            if cards
            else 0,
        }

        return jsonify(response), 200

    except Exception as e:
        return jsonify({"error": f"Generation failed: {str(e)}"}), 500


@ai_bp.route("/enhance-card", methods=["POST"])
def enhance_card():
    """Enhance an existing flashcard"""
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "No data provided"}), 400

        # For now, return the original card with slight improvements
        # This could be enhanced with actual AI processing
        original_card = data.get("card", {})
        context = data.get("context", "")

        # Simulate enhancement processing
        time.sleep(random.uniform(0.5, 1.5))

        enhanced_card = original_card.copy()
        enhanced_card["confidence"] = min(
            0.98, enhanced_card.get("confidence", 0.8) + 0.1
        )

        if context:
            enhanced_card[
                "explanation"
            ] = f"{enhanced_card.get('explanation', '')} Additional context: {context}"

        return jsonify({"enhanced_card": enhanced_card}), 200

    except Exception as e:
        return jsonify({"error": f"Enhancement failed: {str(e)}"}), 500


@ai_bp.route("/generate-similar", methods=["POST"])
def generate_similar_cards():
    """Generate similar cards based on an existing card"""
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "No data provided"}), 400

        base_card = data.get("card", {})
        count = data.get("count", 3)

        if not base_card:
            return jsonify({"error": "Base card is required"}), 400

        # Simulate processing time
        time.sleep(random.uniform(0.8, 1.8))

        base_question = base_card.get("question", "")
        base_answer = base_card.get("answer", "")
        base_topic = (
            base_card.get("tags", ["topic"])[0] if base_card.get("tags") else "topic"
        )

        similar_cards = []
        variations = [
            ("Alternative", "A different perspective on"),
            ("Advanced", "A more detailed look at"),
            ("Related", "A concept related to"),
            ("Practical", "A practical application of"),
            ("Example", "An example of"),
        ]

        for i in range(min(count, len(variations))):
            var_type, var_prefix = variations[i]

            similar_card = {
                "question": f"{var_prefix} {base_topic}: {base_question.replace('What is', 'How does')}",
                "answer": f"{var_prefix} the concept: {base_answer}",
                "explanation": f"This is a {var_type.lower()} card based on the original concept.",
                "difficulty": base_card.get("difficulty", "medium"),
                "tags": base_card.get("tags", []) + [f"variation-{i+1}"],
                "confidence": random.uniform(0.75, 0.92),
            }
            similar_cards.append(similar_card)

        return jsonify({"similar_cards": similar_cards}), 200

    except Exception as e:
        return jsonify({"error": f"Similar card generation failed: {str(e)}"}), 500


@ai_bp.route("/generate-answer", methods=["POST"])
def generate_answer():
    """Generate an AI answer for a given question"""
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "No data provided"}), 400

        question = data.get("question", "").strip()
        if not question:
            return jsonify({"error": "Question is required"}), 400

        context = data.get("context", "").strip()  # Optional topic/subject context
        difficulty = data.get("difficulty", "medium")
        deck_topic = data.get(
            "deck_topic", ""
        ).strip()  # Deck context for better answers

        # Validate inputs
        if difficulty not in ["easy", "medium", "hard"]:
            return jsonify({"error": "Difficulty must be easy, medium, or hard"}), 400

        # Simulate processing time for realistic feel
        time.sleep(random.uniform(0.8, 2.0))

        # Generate answer based on question
        answer_data = generate_answer_for_question(
            question, context, difficulty, deck_topic
        )

        response = {
            "answer": answer_data["answer"],
            "explanation": answer_data.get("explanation"),
            "confidence": answer_data.get("confidence", 0.85),
            "sources": answer_data.get("sources", []),
            "difficulty": difficulty,
            "generation_time": random.uniform(0.9, 2.3),
            "model_version": "gpt-4-preview",
            "suggested_tags": answer_data.get("suggested_tags", []),
        }

        return jsonify(response), 200

    except Exception as e:
        return jsonify({"error": f"Answer generation failed: {str(e)}"}), 500


def generate_answer_for_question(
    question, context="", difficulty="medium", deck_topic=""
):
    """Generate an intelligent answer for a given question"""

    question_lower = question.lower()

    # Analyze question type and generate appropriate answer
    if any(word in question_lower for word in ["what is", "define", "definition"]):
        return generate_definition_answer(question, context, difficulty, deck_topic)
    elif any(
        word in question_lower
        for word in ["how does", "how do", "how to", "explain how"]
    ):
        return generate_process_answer(question, context, difficulty, deck_topic)
    elif any(
        word in question_lower for word in ["why", "what's the purpose", "importance"]
    ):
        return generate_purpose_answer(question, context, difficulty, deck_topic)
    elif any(word in question_lower for word in ["when", "what year", "timeline"]):
        return generate_temporal_answer(question, context, difficulty, deck_topic)
    elif any(word in question_lower for word in ["where", "location", "found"]):
        return generate_location_answer(question, context, difficulty, deck_topic)
    elif any(
        word in question_lower for word in ["who", "inventor", "developer", "created"]
    ):
        return generate_attribution_answer(question, context, difficulty, deck_topic)
    elif any(
        word in question_lower for word in ["compare", "difference", "vs", "versus"]
    ):
        return generate_comparison_answer(question, context, difficulty, deck_topic)
    elif any(word in question_lower for word in ["list", "name", "examples", "types"]):
        return generate_list_answer(question, context, difficulty, deck_topic)
    else:
        return generate_general_answer(question, context, difficulty, deck_topic)


def generate_definition_answer(question, context, difficulty, deck_topic):
    """Generate definition-style answers"""

    # Extract the term being defined
    term = extract_term_from_question(question)

    # Check if we have specific knowledge
    if deck_topic.lower() == "fuel system" and any(
        word in term.lower() for word in ["fuel pump", "injector", "filter", "rail"]
    ):
        fuel_definitions = {
            "fuel pump": {
                "answer": "An electric or mechanical device that moves fuel from the tank to the engine, creating the necessary pressure for proper fuel delivery.",
                "explanation": "Modern vehicles use electric fuel pumps for better control and efficiency.",
                "tags": ["pump", "components"],
            },
            "fuel injector": {
                "answer": "A precision valve that sprays atomized fuel into the engine's intake or combustion chamber at precisely timed intervals.",
                "explanation": "Fuel injectors provide much more accurate fuel delivery than carburetors.",
                "tags": ["injector", "precision"],
            },
            "fuel filter": {
                "answer": "A filtration device that removes contaminants and impurities from fuel before it reaches the engine components.",
                "explanation": "Clean fuel is essential for optimal engine performance and component longevity.",
                "tags": ["filter", "maintenance"],
            },
        }

        for key, definition in fuel_definitions.items():
            if key in term.lower():
                return {
                    "answer": definition["answer"],
                    "explanation": definition["explanation"],
                    "confidence": random.uniform(0.88, 0.96),
                    "suggested_tags": definition["tags"],
                }

    # Generic definition generation
    complexity = (
        "comprehensive"
        if difficulty == "hard"
        else "clear"
        if difficulty == "medium"
        else "simple"
    )

    answer = f"{term} is a {complexity} concept"
    if context:
        answer += f" in {context}"
    if deck_topic:
        answer += f" related to {deck_topic}"

    answer += f" that encompasses key principles and applications in its field."

    return {
        "answer": answer,
        "explanation": f"This definition provides a {complexity} overview suitable for {difficulty} level understanding.",
        "confidence": random.uniform(0.75, 0.89),
        "suggested_tags": [term.lower(), difficulty, "definition"],
    }


def generate_process_answer(question, context, difficulty, deck_topic):
    """Generate process/mechanism answers"""

    process = extract_term_from_question(question)

    # Fuel system specific processes
    if deck_topic.lower() == "fuel system":
        fuel_processes = {
            "fuel pump": "The fuel pump creates suction to draw fuel from the tank, then uses pressure to push it through fuel lines to the engine. Electric pumps use an impeller mechanism for consistent flow.",
            "fuel injection": "Fuel injection works by electronically controlling precise valve opening times to spray atomized fuel at optimal moments during the engine cycle, ensuring proper air-fuel mixture.",
            "pressure regulation": "Fuel pressure regulation maintains consistent pressure using a spring-loaded diaphragm that opens a return path when pressure exceeds specifications, typically 40-60 PSI.",
        }

        for key, process_desc in fuel_processes.items():
            if key in process.lower():
                return {
                    "answer": process_desc,
                    "explanation": "This describes the mechanical and electronic processes involved in modern fuel systems.",
                    "confidence": random.uniform(0.86, 0.94),
                    "suggested_tags": [key.replace(" ", "_"), "process", "operation"],
                }

    # Generic process answer
    answer = f"{process} operates through a series of coordinated steps and mechanisms"
    if context:
        answer += f" within the {context} domain"
    answer += f", involving both mechanical and systematic processes to achieve its intended function."

    return {
        "answer": answer,
        "explanation": f"This explains the operational mechanism at a {difficulty} level.",
        "confidence": random.uniform(0.73, 0.87),
        "suggested_tags": [process.lower(), "process", difficulty],
    }


def generate_purpose_answer(question, context, difficulty, deck_topic):
    """Generate purpose/importance answers"""

    subject = extract_term_from_question(question)

    answer = f"{subject} is important because it provides essential functionality"
    if deck_topic:
        answer += f" in {deck_topic} systems"
    answer += (
        f", ensuring optimal performance, safety, and efficiency in its applications."
    )

    return {
        "answer": answer,
        "explanation": f"This explains the significance and value proposition of {subject}.",
        "confidence": random.uniform(0.76, 0.88),
        "suggested_tags": [subject.lower(), "importance", "purpose"],
    }


def generate_temporal_answer(question, context, difficulty, deck_topic):
    """Generate time-based answers"""

    subject = extract_term_from_question(question)

    answer = (
        f"{subject} development occurred over time through technological advancement"
    )
    if context:
        answer += f" in the {context} field"
    answer += f", with significant milestones marking its evolution and adoption."

    return {
        "answer": answer,
        "explanation": "This provides historical context and timeline information.",
        "confidence": random.uniform(0.71, 0.84),
        "suggested_tags": [subject.lower(), "history", "timeline"],
    }


def generate_location_answer(question, context, difficulty, deck_topic):
    """Generate location-based answers"""

    subject = extract_term_from_question(question)

    answer = f"{subject} is typically located in specific positions"
    if deck_topic:
        answer += f" within {deck_topic} configurations"
    answer += f", strategically placed for optimal accessibility and functionality."

    return {
        "answer": answer,
        "explanation": "This describes typical placement and positioning considerations.",
        "confidence": random.uniform(0.74, 0.86),
        "suggested_tags": [subject.lower(), "location", "placement"],
    }


def generate_attribution_answer(question, context, difficulty, deck_topic):
    """Generate attribution/creator answers"""

    subject = extract_term_from_question(question)

    answer = f"{subject} was developed by engineers and researchers"
    if context:
        answer += f" specializing in {context}"
    answer += f" through collaborative efforts and technological innovation over time."

    return {
        "answer": answer,
        "explanation": "This provides information about the creators and development history.",
        "confidence": random.uniform(0.72, 0.85),
        "suggested_tags": [subject.lower(), "creator", "history"],
    }


def generate_comparison_answer(question, context, difficulty, deck_topic):
    """Generate comparison answers"""

    terms = extract_comparison_terms(question)

    answer = f"The key differences between {terms[0]} and {terms[1]} include their design, functionality, and applications"
    if deck_topic:
        answer += f" within {deck_topic} contexts"
    answer += f", each offering distinct advantages for specific use cases."

    return {
        "answer": answer,
        "explanation": "This highlights the main distinguishing characteristics and trade-offs.",
        "confidence": random.uniform(0.77, 0.89),
        "suggested_tags": [terms[0].lower(), terms[1].lower(), "comparison"],
    }


def generate_list_answer(question, context, difficulty, deck_topic):
    """Generate list-style answers"""

    subject = extract_term_from_question(question)

    answer = f"The main types/examples of {subject} include: 1) Primary variants with standard features, 2) Advanced models with enhanced capabilities, 3) Specialized versions for specific applications"
    if deck_topic:
        answer += f" within {deck_topic} systems"
    answer += f"."

    return {
        "answer": answer,
        "explanation": "This provides a structured breakdown of the main categories or examples.",
        "confidence": random.uniform(0.75, 0.87),
        "suggested_tags": [subject.lower(), "types", "examples"],
    }


def generate_general_answer(question, context, difficulty, deck_topic):
    """Generate general answers for unclassified questions"""

    answer = f"This question relates to fundamental concepts"
    if context:
        answer += f" in {context}"
    if deck_topic:
        answer += f" concerning {deck_topic}"
    answer += f", involving key principles and practical applications that are essential for understanding the subject matter."

    return {
        "answer": answer,
        "explanation": "This provides a general response covering the main aspects of the question.",
        "confidence": random.uniform(0.70, 0.82),
        "suggested_tags": ["general", difficulty, "overview"],
    }


def extract_term_from_question(question):
    """Extract the main term/subject from a question"""
    # Simple extraction - in production this would be more sophisticated
    question = question.replace("?", "").strip()

    # Remove common question words
    question_words = [
        "what",
        "is",
        "how",
        "does",
        "do",
        "why",
        "when",
        "where",
        "who",
        "the",
        "a",
        "an",
    ]
    words = [word for word in question.split() if word.lower() not in question_words]

    if words:
        return " ".join(words[:3])  # Take first few meaningful words
    return "concept"


def extract_comparison_terms(question):
    """Extract terms being compared from a question"""
    # Simple extraction for comparison questions
    if " and " in question:
        parts = question.split(" and ")
        if len(parts) >= 2:
            term1 = parts[0].split()[-1] if parts[0].split() else "concept1"
            term2 = parts[1].split()[0] if parts[1].split() else "concept2"
            return [term1, term2]

    return ["concept1", "concept2"]


@ai_bp.route("/topics/suggestions", methods=["GET"])
def get_topic_suggestions():
    """Get topic suggestions for AI generation"""
    suggestions = {
        "popular": [
            "Spanish verbs",
            "Python programming",
            "Cell biology",
            "World War II",
            "React hooks",
            "Fuel system",
            "Calculus derivatives",
            "French vocabulary",
        ],
        "categories": {
            "Language Learning": [
                "Spanish verbs",
                "French vocabulary",
                "German grammar",
                "Japanese hiragana",
            ],
            "Programming": [
                "Python basics",
                "React hooks",
                "JavaScript ES6",
                "SQL queries",
            ],
            "Science": [
                "Cell biology",
                "Chemistry bonds",
                "Physics mechanics",
                "Organic compounds",
            ],
            "History": [
                "World War II",
                "Roman Empire",
                "American Revolution",
                "Ancient Egypt",
            ],
            "Automotive": [
                "Fuel system",
                "Engine components",
                "Brake system",
                "Electrical system",
            ],
            "Mathematics": [
                "Calculus derivatives",
                "Algebra equations",
                "Geometry theorems",
                "Statistics",
            ],
        },
    }

    return jsonify(suggestions), 200
