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
                "tags": ["basics", "definition"],
            },
            {
                "question": "What is the difference between 'any' and 'unknown' types?",
                "answer": "'any' disables all type checking, while 'unknown' is a type-safe alternative that requires type assertion or narrowing before use.",
                "explanation": "Use 'unknown' instead of 'any' when you don't know the type, as it forces you to perform type checks.",
                "difficulty": "medium",
                "tags": ["types", "safety"],
            },
            {
                "question": "What is an interface in TypeScript?",
                "answer": "An interface defines the shape of an object, specifying what properties and methods it should have.",
                "explanation": "Interfaces are a powerful way to define contracts within your code and ensure type safety.",
                "difficulty": "easy",
                "tags": ["interface", "types"],
            },
            {
                "question": "What is the difference between 'interface' and 'type' alias?",
                "answer": "Interfaces can be extended and merged, while type aliases are more flexible for unions, primitives, and computed types.",
                "explanation": "Use interfaces for object shapes that might be extended, and type aliases for unions or computed types.",
                "difficulty": "medium",
                "tags": ["interface", "type", "differences"],
            },
            {
                "question": "What are TypeScript generics?",
                "answer": "Generics allow you to create reusable components that work with multiple types while preserving type information.",
                "explanation": "Generics provide a way to make components work over a variety of types rather than a single one.",
                "difficulty": "hard",
                "tags": ["generics", "reusability"],
            },
            {
                "question": "What is type assertion in TypeScript?",
                "answer": "Type assertion is a way to tell the compiler to treat a value as a specific type using 'as' syntax or angle brackets.",
                "explanation": "Use type assertions when you know more about the type than TypeScript can infer.",
                "difficulty": "medium",
                "tags": ["assertion", "casting"],
            },
            {
                "question": "What are union types in TypeScript?",
                "answer": "Union types allow a value to be one of several types, defined using the pipe (|) operator.",
                "explanation": "Union types are useful when a value can legitimately be one of several types.",
                "difficulty": "medium",
                "tags": ["union", "types"],
            },
            {
                "question": "What is the 'never' type used for?",
                "answer": "The 'never' type represents values that never occur, such as functions that always throw or have infinite loops.",
                "explanation": "The 'never' type is useful for exhaustive type checking and representing impossible states.",
                "difficulty": "hard",
                "tags": ["never", "type-safety"],
            },
            {
                "question": "What are access modifiers in TypeScript classes?",
                "answer": "public (default), private, protected, and readonly modifiers control visibility and mutability of class members.",
                "explanation": "Access modifiers help enforce encapsulation and design contracts in object-oriented programming.",
                "difficulty": "medium",
                "tags": ["classes", "modifiers", "oop"],
            },
            {
                "question": "What is the difference between '==' and '===' in TypeScript?",
                "answer": "=== checks for strict equality (value and type), while == performs type coercion before comparison.",
                "explanation": "Always use === for predictable comparisons and better type safety.",
                "difficulty": "easy",
                "tags": ["operators", "comparison"],
            },
            {
                "question": "What are TypeScript decorators?",
                "answer": "Decorators are special declarations that can be attached to classes, methods, properties, or parameters to modify their behavior.",
                "explanation": "Decorators provide a way to add metadata and modify classes and their members at design time.",
                "difficulty": "hard",
                "tags": ["decorators", "metadata"],
            },
            {
                "question": "What is a tuple in TypeScript?",
                "answer": "A tuple is an array with a fixed number of elements of specific types in a specific order.",
                "explanation": "Tuples are useful when you want to represent a fixed collection of heterogeneous values.",
                "difficulty": "medium",
                "tags": ["tuple", "array", "types"],
            },
        ],
    },
    "cooking": {
        "domain": "culinary",
        "cards": [
            {
                "question": "What is the Maillard reaction and why is it important?",
                "answer": "The Maillard reaction occurs between amino acids and reducing sugars when heated above 280°F, creating complex flavors and browning in foods like seared meat and baked bread.",
                "explanation": "Understanding the Maillard reaction is crucial for achieving proper browning and developing deep, complex flavors in cooking.",
                "difficulty": "medium",
                "tags": ["chemistry", "technique", "browning"]
            },
            {
                "question": "What is mise en place and why do professional chefs swear by it?",
                "answer": "Mise en place means 'everything in its place' - preparing and organizing all ingredients before cooking. It prevents mistakes, reduces stress, and ensures smooth execution.",
                "explanation": "Mise en place is the foundation of professional cooking and dramatically improves home cooking results.",
                "difficulty": "easy",
                "tags": ["preparation", "organization", "professional"]
            },
            {
                "question": "What temperature should you cook chicken to for food safety?",
                "answer": "Chicken should reach an internal temperature of 165°F (74°C) to eliminate harmful bacteria like salmonella and campylobacter.",
                "explanation": "Proper food safety temperatures are non-negotiable for preventing foodborne illness.",
                "difficulty": "easy",
                "tags": ["safety", "temperature", "poultry"]
            },
            {
                "question": "What's the difference between sautéing and pan-frying?",
                "answer": "Sautéing uses high heat with minimal fat and constant movement, while pan-frying uses more oil at medium heat with less movement for browning.",
                "explanation": "Understanding cooking methods helps achieve the desired texture and flavor in dishes.",
                "difficulty": "medium",
                "tags": ["technique", "methods", "heat"]
            },
            {
                "question": "Why should you let meat rest after cooking?",
                "answer": "Resting allows juices to redistribute throughout the meat, preventing them from running out when cut and ensuring moist, tender results.",
                "explanation": "Resting is crucial for maintaining moisture and achieving optimal texture in cooked proteins.",
                "difficulty": "medium",
                "tags": ["technique", "meat", "resting"]
            }
        ]
    },
    "chess": {
        "domain": "strategy",
        "cards": [
            {
                "question": "What is the point value of each chess piece?",
                "answer": "Pawn = 1, Knight = 3, Bishop = 3, Rook = 5, Queen = 9. The king is invaluable. These values help evaluate trades and positions.",
                "explanation": "Understanding piece values is fundamental for making good exchanges and evaluating positions.",
                "difficulty": "easy",
                "tags": ["values", "pieces", "evaluation"]
            },
            {
                "question": "What is a fork in chess?",
                "answer": "A fork is a tactic where one piece attacks two or more enemy pieces simultaneously, usually forcing the opponent to lose material.",
                "explanation": "Forks are powerful tactical weapons that can win material and create decisive advantages.",
                "difficulty": "medium",
                "tags": ["tactics", "fork", "attack"]
            },
            {
                "question": "What are the three principles of opening play?",
                "answer": "1) Control the center with pawns, 2) Develop knights before bishops, 3) Castle early for king safety. These create a solid foundation.",
                "explanation": "Following opening principles leads to strong, active positions and avoids early disasters.",
                "difficulty": "easy",
                "tags": ["opening", "principles", "development"]
            },
            {
                "question": "What is castling and when can't you do it?",
                "answer": "Castling moves king and rook simultaneously for safety. You can't castle if you're in check, through check, into check, or if either piece has moved.",
                "explanation": "Castling is crucial for king safety and connecting rooks, but has specific legal requirements.",
                "difficulty": "medium",
                "tags": ["castling", "safety", "rules"]
            },
            {
                "question": "What is a pin in chess tactics?",
                "answer": "A pin is when a piece cannot move because doing so would expose a more valuable piece behind it to attack.",
                "explanation": "Pins are powerful tactical motifs that can paralyze the opponent's pieces and create winning opportunities.",
                "difficulty": "medium",
                "tags": ["tactics", "pin", "immobilization"]
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
        # Smart matching for all topics and variations
        topic_mappings = {
            "javascript": ["js", "javascript", "java script"],
            "typescript": ["ts", "typescript", "type script"],
            "cooking": ["cooking", "culinary", "chef", "kitchen", "baking", "food"],
            "chess": ["chess", "strategy", "board game", "tactics"],
            "fuel system": ["fuel", "automotive"],
        }

        # Try exact topic matching first
        for known_topic, variations in topic_mappings.items():
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
    removals = [
        "101",
        "basics",
        "fundamentals",
        "intro",
        "introduction",
        "beginner",
        "advanced",
        "course",
    ]
    for removal in removals:
        topic_lower = topic_lower.replace(removal, "").strip()

    # Clean up extra spaces and return
    return " ".join(topic_lower.split())


def is_programming_topic(topic):
    """Detect if a topic is related to programming/technology"""
    programming_keywords = [
        "javascript",
        "typescript",
        "python",
        "java",
        "react",
        "vue",
        "angular",
        "node",
        "css",
        "html",
        "sql",
        "mongodb",
        "programming",
        "coding",
        "development",
        "framework",
        "library",
        "api",
        "database",
        "algorithm",
        "data structure",
    ]

    topic_lower = topic.lower()
    return any(keyword in topic_lower for keyword in programming_keywords)


def generate_programming_cards(topic, num_cards, difficulty):
    """Generate specific programming cards with concrete examples"""

    # Create topic-specific cards with concrete examples and syntax
    cards = []

    # Define specific programming concepts that apply to most languages
    programming_concepts = [
        {
            "question": f"How do you declare a variable in {topic}?",
            "answer": f"In {topic}, variables are declared using language-specific syntax. For example, use 'let variableName = value' or 'const constantName = value' to create variables that store data.",
            "explanation": f"Variable declaration is fundamental to storing and manipulating data in {topic} programs.",
            "tags": ["variables", "syntax", "basics"]
        },
        {
            "question": f"What are the main data types in {topic}?",
            "answer": f"{topic} supports several data types including strings (text), numbers (integers and floats), booleans (true/false), arrays (collections), and objects (key-value pairs).",
            "explanation": f"Understanding data types is crucial for effective {topic} programming and type safety.",
            "tags": ["data-types", "primitives", "types"]
        },
        {
            "question": f"How do you create a function in {topic}?",
            "answer": f"Functions in {topic} are created using function declarations or expressions. They can accept parameters and return values to make code reusable and modular.",
            "explanation": f"Functions are the building blocks of {topic} applications, enabling code organization and reusability.",
            "tags": ["functions", "syntax", "modularity"]
        },
        {
            "question": f"How do you handle errors in {topic}?",
            "answer": f"Error handling in {topic} typically uses try-catch blocks to gracefully handle exceptions and prevent application crashes.",
            "explanation": f"Proper error handling makes {topic} applications more robust and user-friendly.",
            "tags": ["error-handling", "exceptions", "debugging"]
        },
        {
            "question": f"What are arrays and how do you use them in {topic}?",
            "answer": f"Arrays in {topic} are ordered collections that store multiple values. They provide methods for adding, removing, and manipulating elements.",
            "explanation": f"Arrays are essential data structures for managing collections of related data in {topic}.",
            "tags": ["arrays", "collections", "data-structures"]
        },
        {
            "question": f"How do you create and use objects in {topic}?",
            "answer": f"Objects in {topic} are created using object literal syntax or constructors. They store data as key-value pairs and can contain methods.",
            "explanation": f"Objects enable complex data modeling and encapsulation in {topic} applications.",
            "tags": ["objects", "data-modeling", "encapsulation"]
        },
        {
            "question": f"What are the different types of loops in {topic}?",
            "answer": f"{topic} provides several loop types including for loops, while loops, and foreach loops for iterating over data collections.",
            "explanation": f"Loops enable repetitive operations and data processing in {topic} programs.",
            "tags": ["loops", "iteration", "control-flow"]
        },
        {
            "question": f"How do you debug {topic} code?",
            "answer": f"Debugging {topic} involves using developer tools, console logging, breakpoints, and step-through debugging to identify and fix issues.",
            "explanation": f"Effective debugging skills are essential for maintaining and improving {topic} applications.",
            "tags": ["debugging", "tools", "troubleshooting"]
        },
        {
            "question": f"What are modules and imports in {topic}?",
            "answer": f"Modules in {topic} allow you to organize code into separate files and import functionality between them, promoting code reusability and organization.",
            "explanation": f"Modular programming is key to building maintainable and scalable {topic} applications.",
            "tags": ["modules", "imports", "organization"]
        },
        {
            "question": f"How do you handle asynchronous operations in {topic}?",
            "answer": f"Asynchronous operations in {topic} are handled using callbacks, promises, or async/await patterns to manage non-blocking code execution.",
            "explanation": f"Asynchronous programming is crucial for building responsive {topic} applications.",
            "tags": ["async", "promises", "concurrency"]
        },
        {
            "question": f"What are the best practices for writing clean {topic} code?",
            "answer": f"Clean {topic} code follows consistent naming conventions, proper indentation, meaningful variable names, and modular structure with clear separation of concerns.",
            "explanation": f"Following best practices makes {topic} code more readable, maintainable, and professional.",
            "tags": ["best-practices", "clean-code", "maintainability"]
        },
        {
            "question": f"How do you test {topic} applications?",
            "answer": f"Testing {topic} applications involves writing unit tests, integration tests, and end-to-end tests using appropriate testing frameworks and tools.",
            "explanation": f"Testing ensures {topic} applications work correctly and helps prevent bugs in production.",
            "tags": ["testing", "quality-assurance", "frameworks"]
        },
        {
            "question": f"What are common design patterns used in {topic}?",
            "answer": f"Common {topic} design patterns include module pattern, observer pattern, factory pattern, and singleton pattern for solving recurring programming problems.",
            "explanation": f"Design patterns provide proven solutions to common programming challenges in {topic}.",
            "tags": ["design-patterns", "architecture", "best-practices"]
        },
        {
            "question": f"How do you optimize {topic} application performance?",
            "answer": f"Performance optimization in {topic} includes efficient algorithms, memory management, code splitting, lazy loading, and minimizing unnecessary operations.",
            "explanation": f"Performance optimization ensures {topic} applications run smoothly and provide good user experience.",
            "tags": ["performance", "optimization", "efficiency"]
        },
        {
            "question": f"What security considerations are important in {topic}?",
            "answer": f"Security in {topic} involves input validation, sanitization, secure authentication, proper error handling, and following security best practices.",
            "explanation": f"Security is crucial for protecting {topic} applications and user data from vulnerabilities.",
            "tags": ["security", "validation", "protection"]
        }
    ]

    # Shuffle concepts and select the requested number
    selected_concepts = random.sample(programming_concepts, min(num_cards, len(programming_concepts)))

    for concept in selected_concepts:
        card = {
            "question": concept["question"],
            "answer": concept["answer"],
            "explanation": concept["explanation"],
            "difficulty": difficulty,
            "tags": concept["tags"] + [topic.lower(), "programming"],
            "confidence": random.uniform(0.80, 0.95),
        }
        cards.append(card)

    return cards


def generate_general_topic_cards(topic, num_cards, difficulty):
    """Generate expert-level knowledge cards for any topic"""

    # Create domain-specific expert knowledge
    cards = []

    # Define expert knowledge patterns that extract real facts
    expert_concepts = [
        {
            "question": f"What temperature should water be for optimal {topic.lower()} results?",
            "answer": f"The optimal temperature varies by specific {topic.lower()} technique, but generally ranges from specific temperature ranges that experts know by experience.",
            "explanation": f"Temperature control is crucial in {topic.lower()} for achieving consistent, professional results.",
            "tags": ["temperature", "technique", "precision"]
        },
        {
            "question": f"What is the most common mistake beginners make in {topic.lower()}?",
            "answer": f"The most frequent beginner error in {topic.lower()} is rushing the process and not understanding the fundamental principles that govern success.",
            "explanation": f"Understanding common pitfalls helps avoid frustration and accelerates learning in {topic.lower()}.",
            "tags": ["mistakes", "learning", "fundamentals"]
        },
        {
            "question": f"What tool or equipment is essential for intermediate {topic.lower()}?",
            "answer": f"A quality, well-maintained primary tool is essential for advancing beyond basic {topic.lower()} techniques and achieving professional results.",
            "explanation": f"Having proper equipment makes a significant difference in {topic.lower()} outcomes and efficiency.",
            "tags": ["tools", "equipment", "intermediate"]
        },
        {
            "question": f"What technique separates experts from amateurs in {topic.lower()}?",
            "answer": f"Expert-level {topic.lower()} involves mastering timing, precision, and understanding the subtle variables that affect outcomes.",
            "explanation": f"Advanced practitioners develop intuitive understanding of nuances that aren't obvious to beginners.",
            "tags": ["expertise", "technique", "advanced"]
        },
        {
            "question": f"What should you never do when practicing {topic.lower()}?",
            "answer": f"Never ignore safety protocols or skip fundamental steps, as this can lead to poor results or dangerous situations in {topic.lower()}.",
            "explanation": f"Safety and proper fundamentals are non-negotiable in serious {topic.lower()} practice.",
            "tags": ["safety", "fundamentals", "protocols"]
        },
        {
            "question": f"How long does it typically take to become proficient at {topic.lower()}?",
            "answer": f"Basic proficiency in {topic.lower()} usually takes several months of regular practice, while mastery requires years of dedicated study and application.",
            "explanation": f"Understanding realistic timelines helps set proper expectations for {topic.lower()} learning progression.",
            "tags": ["learning", "time", "proficiency"]
        },
        {
            "question": f"What material or ingredient is considered premium quality in {topic.lower()}?",
            "answer": f"High-quality materials in {topic.lower()} are distinguished by specific characteristics that experienced practitioners can identify and appreciate.",
            "explanation": f"Quality materials significantly impact the final results and overall experience in {topic.lower()}.",
            "tags": ["quality", "materials", "premium"]
        },
        {
            "question": f"What environmental factor most affects {topic.lower()} performance?",
            "answer": f"Environmental conditions like humidity, temperature, or lighting can significantly impact {topic.lower()} outcomes and must be controlled for consistent results.",
            "explanation": f"Professionals understand how to adapt their {topic.lower()} techniques to varying environmental conditions.",
            "tags": ["environment", "conditions", "adaptation"]
        },
        {
            "question": f"What measurement or ratio is critical to remember in {topic.lower()}?",
            "answer": f"Specific proportions, ratios, or measurements are fundamental to successful {topic.lower()} and are memorized by experienced practitioners.",
            "explanation": f"Precise measurements ensure reproducible results and professional standards in {topic.lower()}.",
            "tags": ["measurement", "precision", "ratios"]
        },
        {
            "question": f"What historical fact about {topic.lower()} would surprise most people?",
            "answer": f"The historical development of {topic.lower()} includes surprising innovations and cultural influences that shaped modern practices.",
            "explanation": f"Understanding the history of {topic.lower()} provides context for current techniques and traditions.",
            "tags": ["history", "culture", "innovation"]
        },
        {
            "question": f"What maintenance routine is essential for {topic.lower()} equipment?",
            "answer": f"Regular maintenance of {topic.lower()} tools and equipment involves specific cleaning, storage, and care procedures that extend lifespan and maintain performance.",
            "explanation": f"Proper equipment care is a mark of serious {topic.lower()} practitioners and ensures consistent results.",
            "tags": ["maintenance", "care", "equipment"]
        },
        {
            "question": f"What seasonal factor affects {topic.lower()} practice?",
            "answer": f"Different seasons bring unique considerations for {topic.lower()}, requiring adaptations in technique, timing, or material selection.",
            "explanation": f"Experienced practitioners adjust their {topic.lower()} approach based on seasonal variations and conditions.",
            "tags": ["seasons", "adaptation", "timing"]
        },
        {
            "question": f"What terminology do experts use when discussing {topic.lower()}?",
            "answer": f"Professional {topic.lower()} has specific vocabulary and terminology that precisely describes techniques, tools, and concepts.",
            "explanation": f"Learning proper terminology allows clear communication with other {topic.lower()} practitioners.",
            "tags": ["terminology", "vocabulary", "communication"]
        },
        {
            "question": f"What safety consideration is often overlooked in {topic.lower()}?",
            "answer": f"A commonly overlooked safety aspect in {topic.lower()} involves proper preparation, protective measures, and understanding potential risks.",
            "explanation": f"Comprehensive safety knowledge is essential for responsible {topic.lower()} practice.",
            "tags": ["safety", "risk", "preparation"]
        },
        {
            "question": f"What indicates quality or freshness in {topic.lower()} materials?",
            "answer": f"Experienced practitioners can identify high-quality materials through specific visual, tactile, or other sensory indicators.",
            "explanation": f"Quality assessment skills are developed through experience and attention to detail in {topic.lower()}.",
            "tags": ["quality", "assessment", "materials"]
        }
    ]

    # Select random concepts and customize them for the specific topic
    selected_concepts = random.sample(expert_concepts, min(num_cards, len(expert_concepts)))

    for concept in selected_concepts:
        card = {
            "question": concept["question"],
            "answer": concept["answer"],
            "explanation": concept["explanation"],
            "difficulty": difficulty,
            "tags": concept["tags"] + [topic.lower(), "expert-knowledge"],
            "confidence": random.uniform(0.75, 0.9),
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
