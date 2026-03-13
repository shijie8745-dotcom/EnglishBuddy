import Foundation

// MARK: - Dialogue Script Models

struct DialogueScript: Codable {
    let unit: Int
    let title: String
    let opening: [DialogueRound]
    let rounds: [DialogueRound]
}

struct DialogueRound: Codable {
    let round: Int
    let speaker: String
    let text: String
    let expectedResponse: String?
    let keyVocabulary: [String]?
    let keyPattern: String?
    let hint: String?
}

// MARK: - Script Loader

class DialogueScriptLoader {
    static let shared = DialogueScriptLoader()

    private var scripts: [Int: DialogueScript] = [:]

    private init() {
        loadAllScripts()
    }

    func script(for unitId: Int) -> DialogueScript? {
        return scripts[unitId]
    }

    private func loadAllScripts() {
        // Unit 0 - Hello
        scripts[0] = DialogueScript(
            unit: 0,
            title: "Hello",
            opening: [
                DialogueRound(round: 0, speaker: "sam", text: "Hello hello! 🎵 How are you today?", expectedResponse: "I'm happy/good/great", keyVocabulary: nil, keyPattern: nil, hint: nil),
                DialogueRound(round: 1, speaker: "sam", text: "Wonderful! Are you ready to learn and have fun?", expectedResponse: "Yes, I'm ready", keyVocabulary: nil, keyPattern: nil, hint: nil)
            ],
            rounds: [
                DialogueRound(round: 2, speaker: "sam", text: "Perfect! Let me tell you about my friends at the Friendly Farm. Can you count with me? One, two...", expectedResponse: "Three, four, five", keyVocabulary: ["one", "two", "three", "four", "five"], keyPattern: nil, hint: "跟着 Sam 一起数数"),
                DialogueRound(round: 3, speaker: "sam", text: "Excellent counting! Now, let me ask you - how old are you?", expectedResponse: "I'm six/seven/eight", keyVocabulary: nil, keyPattern: "I'm [number]", hint: "用 I'm + 你的年龄 来回答"),
                DialogueRound(round: 4, speaker: "sam", text: "Wow, that's great! Do you know what color you like best? I like blue!", expectedResponse: "I like red/blue/green", keyVocabulary: ["red", "blue", "green", "yellow"], keyPattern: "I like [color]", hint: "说出一个你喜欢的颜色"),
                DialogueRound(round: 5, speaker: "sam", text: "Great! What's your name?", expectedResponse: "I'm [name]", keyVocabulary: nil, keyPattern: "I'm [name]", hint: "用 I'm + 你的名字"),
                DialogueRound(round: 6, speaker: "sam", text: "Beautiful! Now let's play a color game. Can you find something red around you?", expectedResponse: "Yes! A red apple/book", keyVocabulary: ["red"], keyPattern: nil, hint: "说出你看到的红色物品"),
                DialogueRound(round: 7, speaker: "sam", text: "Fantastic! Let's count to ten together. One, two, three...", expectedResponse: "Four, five, six, seven, eight, nine, ten", keyVocabulary: ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"], keyPattern: nil, hint: "一起数到十"),
                DialogueRound(round: 8, speaker: "sam", text: "Perfect counting! Can you tell me your name again?", expectedResponse: "I'm [name]", keyVocabulary: nil, keyPattern: "I'm [name]", hint: "再说一遍你的名字"),
                DialogueRound(round: 9, speaker: "sam", text: "Great! What's your favorite color?", expectedResponse: "I like [color]", keyVocabulary: nil, keyPattern: "I like [color]", hint: "说你喜欢的颜色"),
                DialogueRound(round: 10, speaker: "sam", text: "Wonderful! Let's count your fingers! How many fingers do you have?", expectedResponse: "Ten! / I have ten fingers", keyVocabulary: ["ten"], keyPattern: nil, hint: "数一数手指"),
                DialogueRound(round: 11, speaker: "sam", text: "Yes! Now, can you touch something blue?", expectedResponse: "Yes! [blue item]", keyVocabulary: ["blue"], keyPattern: nil, hint: "摸摸蓝色的物品"),
                DialogueRound(round: 12, speaker: "sam", text: "Great job! Can you say the numbers one to five again?", expectedResponse: "One, two, three, four, five", keyVocabulary: ["one", "two", "three", "four", "five"], keyPattern: nil, hint: "再说一遍数字1-5"),
                DialogueRound(round: 13, speaker: "sam", text: "Excellent! Thank you for learning with me today. What's your name one more time?", expectedResponse: "I'm [name]", keyVocabulary: nil, keyPattern: "I'm [name]", hint: "再说一遍名字"),
                DialogueRound(round: 14, speaker: "sam", text: "Bye bye! See you next time!", expectedResponse: "Bye-bye/Goodbye/See you", keyVocabulary: nil, keyPattern: nil, hint: "说再见")
            ]
        )

        // Unit 1 - Our New School
        scripts[1] = DialogueScript(
            unit: 1,
            title: "Our New School",
            opening: [
                DialogueRound(round: 0, speaker: "sam", text: "Hello! Welcome to our new school! 🏫 How are you today?", expectedResponse: "I'm good/happy", keyVocabulary: nil, keyPattern: nil, hint: nil),
                DialogueRound(round: 1, speaker: "sam", text: "Great! Are you ready to explore the classroom?", expectedResponse: "Yes, I'm ready", keyVocabulary: nil, keyPattern: nil, hint: nil)
            ],
            rounds: [
                DialogueRound(round: 2, speaker: "sam", text: "Look around! What's this? 👉 (pointing to a book)", expectedResponse: "It's a book", keyVocabulary: ["book"], keyPattern: "It's a [item]", hint: "用 It's a... 回答"),
                DialogueRound(round: 3, speaker: "sam", text: "Excellent! What's that? 👉 (pointing to a bag)", expectedResponse: "It's a bag", keyVocabulary: ["bag"], keyPattern: "It's a [item]", hint: "那是书包"),
                DialogueRound(round: 4, speaker: "sam", text: "Good! Now, where is your pencil?", expectedResponse: "It's on/in/under the desk", keyVocabulary: ["pencil", "desk"], keyPattern: "It's [preposition] the [place]", hint: "用方位介词回答"),
                DialogueRound(round: 5, speaker: "sam", text: "Perfect! Do you have a pencil case?", expectedResponse: "Yes, I do / No, I don't", keyVocabulary: ["pencil case"], keyPattern: "Yes, I do / No, I don't", hint: "用 Yes, I do 或 No, I don't 回答"),
                DialogueRound(round: 6, speaker: "sam", text: "What's this? 👉 (pointing to a chair)", expectedResponse: "It's a chair", keyVocabulary: ["chair"], keyPattern: "It's a [item]", hint: "这是一把椅子"),
                DialogueRound(round: 7, speaker: "sam", text: "Great! Where is the door?", expectedResponse: "It's there! / It's near the window", keyVocabulary: ["door", "window"], keyPattern: "It's [location]", hint: "指出门的位置"),
                DialogueRound(round: 8, speaker: "sam", text: "Can you find something orange in the classroom?", expectedResponse: "Yes! An orange pencil/crayon", keyVocabulary: ["orange"], keyPattern: nil, hint: "找橙色的物品"),
                DialogueRound(round: 9, speaker: "sam", text: "Wonderful! What's in your bag?", expectedResponse: "A book/pencil/ruler", keyVocabulary: ["book", "pencil", "ruler"], keyPattern: nil, hint: "说出书包里的物品"),
                DialogueRound(round: 10, speaker: "sam", text: "Look! What's that on the desk?", expectedResponse: "It's a crayon/pen/ruler", keyVocabulary: ["crayon", "pen", "ruler"], keyPattern: "It's a [item]", hint: "书桌上有什么"),
                DialogueRound(round: 11, speaker: "sam", text: "Clever! Is your bag on the chair?", expectedResponse: "Yes, it is / No, it isn't", keyVocabulary: ["bag", "chair"], keyPattern: "Yes, it is / No, it isn't", hint: "书包在椅子上吗"),
                DialogueRound(round: 12, speaker: "sam", text: "Where is your book?", expectedResponse: "It's in my bag / on the desk", keyVocabulary: ["book"], keyPattern: "It's [preposition] [location]", hint: "书在哪里"),
                DialogueRound(round: 13, speaker: "sam", text: "Great job! Can you say: This is my pencil?", expectedResponse: "This is my pencil", keyVocabulary: ["pencil"], keyPattern: "This is my [item]", hint: "这是我的铅笔"),
                DialogueRound(round: 14, speaker: "sam", text: "Perfect! Time to say goodbye. See you next time! 👋", expectedResponse: "See you/Goodbye/Bye", keyVocabulary: nil, keyPattern: nil, hint: "说再见")
            ]
        )

        // Unit 2 - All About Us
        scripts[2] = DialogueScript(
            unit: 2,
            title: "All About Us",
            opening: [
                DialogueRound(round: 0, speaker: "sam", text: "Hello friend! 👋 How are you feeling today?", expectedResponse: "I'm happy/good", keyVocabulary: nil, keyPattern: nil, hint: nil),
                DialogueRound(round: 1, speaker: "sam", text: "That's wonderful! Are you ready to learn about our bodies?", expectedResponse: "Yes, I'm ready", keyVocabulary: nil, keyPattern: nil, hint: nil)
            ],
            rounds: [
                DialogueRound(round: 2, speaker: "sam", text: "Touch your head! Can you say 'head'?", expectedResponse: "Head", keyVocabulary: ["head"], keyPattern: nil, hint: "摸摸头，说 head"),
                DialogueRound(round: 3, speaker: "sam", text: "Good! How many eyes do you have?", expectedResponse: "I have two eyes", keyVocabulary: ["eyes", "two"], keyPattern: "I have [number] [body part]", hint: "你有几只眼睛"),
                DialogueRound(round: 4, speaker: "sam", text: "Perfect! Can you touch your ears? 👂", expectedResponse: "Yes! Ears", keyVocabulary: ["ears"], keyPattern: nil, hint: "摸摸耳朵"),
                DialogueRound(round: 5, speaker: "sam", text: "What can you smell with? 👃", expectedResponse: "My nose / I can smell with my nose", keyVocabulary: ["nose"], keyPattern: nil, hint: "用什么闻"),
                DialogueRound(round: 6, speaker: "sam", text: "Right! Show me your hands! 🙌", expectedResponse: "Hands", keyVocabulary: ["hands"], keyPattern: nil, hint: "给我看看你的手"),
                DialogueRound(round: 7, speaker: "sam", text: "How many fingers on one hand?", expectedResponse: "Five", keyVocabulary: ["five", "fingers"], keyPattern: nil, hint: "一只手有几个手指"),
                DialogueRound(round: 8, speaker: "sam", text: "Great counting! Can you clap your hands? 👏", expectedResponse: "Yes! (clap)", keyVocabulary: ["clap"], keyPattern: nil, hint: "拍拍手"),
                DialogueRound(round: 9, speaker: "sam", text: "What do you use to eat? 🍎", expectedResponse: "My mouth", keyVocabulary: ["mouth"], keyPattern: nil, hint: "用什么吃东西"),
                DialogueRound(round: 10, speaker: "sam", text: "Touch your arms! How many arms?", expectedResponse: "Two arms", keyVocabulary: ["arms", "two"], keyPattern: nil, hint: "摸摸手臂"),
                DialogueRound(round: 11, speaker: "sam", text: "Can you stamp your feet? 🦶", expectedResponse: "Yes! (stamp)", keyVocabulary: ["stamp", "feet"], keyPattern: nil, hint: "跺跺脚"),
                DialogueRound(round: 12, speaker: "sam", text: "How do you feel when you're tired? 😴", expectedResponse: "I'm tired", keyVocabulary: ["tired"], keyPattern: "I'm [feeling]", hint: "累了怎么说"),
                DialogueRound(round: 13, speaker: "sam", text: "Are you hungry now? 🍕", expectedResponse: "Yes, I'm hungry / No", keyVocabulary: ["hungry"], keyPattern: "Yes, I'm hungry", hint: "你饿了吗"),
                DialogueRound(round: 14, speaker: "sam", text: "You're doing great! Bye for now! 👋", expectedResponse: "Bye/Goodbye", keyVocabulary: nil, keyPattern: nil, hint: "说再见")
            ]
        )

        // Unit 3 - Fun on the Farm
        scripts[3] = DialogueScript(
            unit: 3,
            title: "Fun on the Farm",
            opening: [
                DialogueRound(round: 0, speaker: "sam", text: "Hello! Welcome to the farm! 🚜 How are you?", expectedResponse: "I'm good", keyVocabulary: nil, keyPattern: nil, hint: nil),
                DialogueRound(round: 1, speaker: "sam", text: "Great! Let's meet the animals! Ready?", expectedResponse: "Yes, ready", keyVocabulary: nil, keyPattern: nil, hint: nil)
            ],
            rounds: [
                DialogueRound(round: 2, speaker: "sam", text: "What's this? 🐄 (Moo! Moo!)", expectedResponse: "It's a cow", keyVocabulary: ["cow", "moo"], keyPattern: "It's a [animal]", hint: "这是什么动物"),
                DialogueRound(round: 3, speaker: "sam", text: "Right! What does a cow say?", expectedResponse: "Moo", keyVocabulary: ["moo"], keyPattern: "[animal] says [sound]", hint: "奶牛怎么叫"),
                DialogueRound(round: 4, speaker: "sam", text: "Listen! 🐷 (Oink oink!) What's that?", expectedResponse: "It's a pig", keyVocabulary: ["pig", "oink"], keyPattern: "It's a [animal]", hint: "那是猪"),
                DialogueRound(round: 5, speaker: "sam", text: "Quack quack! 🦆 What animal is this?", expectedResponse: "It's a duck", keyVocabulary: ["duck", "quack"], keyPattern: "It's a [animal]", hint: "嘎嘎叫的是什么"),
                DialogueRound(round: 6, speaker: "sam", text: "Neigh! 🐴 What do you hear?", expectedResponse: "A horse", keyVocabulary: ["horse", "neigh"], keyPattern: "It's a [animal]", hint: "嘶鸣的是什么"),
                DialogueRound(round: 7, speaker: "sam", text: "Cluck cluck! 🐔 Can you guess?", expectedResponse: "It's a chicken", keyVocabulary: ["chicken", "cluck"], keyPattern: "It's a [animal]", hint: "咯咯叫的"),
                DialogueRound(round: 8, speaker: "sam", text: "What animal says 'baa baa'? 🐑", expectedResponse: "A sheep", keyVocabulary: ["sheep", "baa"], keyPattern: nil, hint: "咩咩叫的是什么"),
                DialogueRound(round: 9, speaker: "sam", text: "Woof woof! 🐕 What's this?", expectedResponse: "It's a dog", keyVocabulary: ["dog"], keyPattern: "It's a [animal]", hint: "汪汪叫的"),
                DialogueRound(round: 10, speaker: "sam", text: "Look! A small animal. Meow! 🐱", expectedResponse: "It's a cat", keyVocabulary: ["cat", "meow"], keyPattern: "It's a [animal]", hint: "喵喵叫的"),
                DialogueRound(round: 11, speaker: "sam", text: "Which animal is big and gives milk?", expectedResponse: "A cow", keyVocabulary: ["cow"], keyPattern: nil, hint: "什么动物很大还产奶"),
                DialogueRound(round: 12, speaker: "sam", text: "Do you like ducks? 🦆", expectedResponse: "Yes, I do / No, I don't", keyVocabulary: ["duck"], keyPattern: "Yes, I do", hint: "你喜欢鸭子吗"),
                DialogueRound(round: 13, speaker: "sam", text: "What's your favorite farm animal?", expectedResponse: "I like [animal]", keyVocabulary: nil, keyPattern: "I like [animal]", hint: "你最喜欢的农场动物"),
                DialogueRound(round: 14, speaker: "sam", text: "Time to go home! Bye bye farm animals! 👋", expectedResponse: "Bye", keyVocabulary: nil, keyPattern: nil, hint: "说再见")
            ]
        )

        // Units 4-9 with similar structure
        loadRemainingUnits()
    }

    private func loadRemainingUnits() {
        // Unit 4 - Food With Friends
        scripts[4] = DialogueScript(
            unit: 4,
            title: "Food With Friends",
            opening: [
                DialogueRound(round: 0, speaker: "sam", text: "Hello! Are you hungry? 🍽️", expectedResponse: "Yes/No", keyVocabulary: nil, keyPattern: nil, hint: nil),
                DialogueRound(round: 1, speaker: "sam", text: "Let's talk about food! Ready?", expectedResponse: "Yes, ready", keyVocabulary: nil, keyPattern: nil, hint: nil)
            ],
            rounds: [
                DialogueRound(round: 2, speaker: "sam", text: "What's this red fruit? 🍎", expectedResponse: "It's an apple", keyVocabulary: ["apple", "red"], keyPattern: "It's a/an [food]", hint: "红色的水果"),
                DialogueRound(round: 3, speaker: "sam", text: "Good! What's yellow and long? 🍌", expectedResponse: "It's a banana", keyVocabulary: ["banana", "yellow"], keyPattern: "It's a [food]", hint: "黄色的长水果"),
                DialogueRound(round: 4, speaker: "sam", text: "Round and orange! 🍊 What is it?", expectedResponse: "It's an orange", keyVocabulary: ["orange"], keyPattern: "It's a/an [food]", hint: "圆圆的橙色水果"),
                DialogueRound(round: 5, speaker: "sam", text: "Do you like apples? 🍎", expectedResponse: "Yes, I do / No, I don't", keyVocabulary: ["apple"], keyPattern: "Yes, I do", hint: "你喜欢苹果吗"),
                DialogueRound(round: 6, speaker: "sam", text: "What's your favorite fruit?", expectedResponse: "I like [fruit]", keyVocabulary: nil, keyPattern: "I like [food]", hint: "你最喜欢的水果"),
                DialogueRound(round: 7, speaker: "sam", text: "Look! 🍇 What are these?", expectedResponse: "They're grapes", keyVocabulary: ["grapes"], keyPattern: "They're [food]", hint: "这些是什么"),
                DialogueRound(round: 8, speaker: "sam", text: "Are you thirsty? 🥤", expectedResponse: "Yes, I am / No", keyVocabulary: ["thirsty"], keyPattern: "Yes, I am", hint: "你渴吗"),
                DialogueRound(round: 9, speaker: "sam", text: "What do you want to drink?", expectedResponse: "I'd like water/juice/milk", keyVocabulary: ["water", "juice", "milk"], keyPattern: "I'd like [drink]", hint: "你想喝什么"),
                DialogueRound(round: 10, speaker: "sam", text: "🍰 What's this yummy food?", expectedResponse: "It's cake", keyVocabulary: ["cake"], keyPattern: "It's [food]", hint: "这是什么好吃的"),
                DialogueRound(round: 11, speaker: "sam", text: "What's in a sandwich? 🥪", expectedResponse: "Bread/meat/vegetables", keyVocabulary: ["sandwich"], keyPattern: nil, hint: "三明治里有什么"),
                DialogueRound(round: 12, speaker: "sam", text: "Can I have some water, please? 💧", expectedResponse: "Yes, here you are", keyVocabulary: ["water"], keyPattern: "Yes, here you are", hint: "礼貌回应"),
                DialogueRound(round: 13, speaker: "sam", text: "Thank you! What do you say?", expectedResponse: "You're welcome", keyVocabulary: nil, keyPattern: "You're welcome", hint: "回答谢谢"),
                DialogueRound(round: 14, speaker: "sam", text: "Yummy lesson! See you! 🍕👋", expectedResponse: "Bye", keyVocabulary: nil, keyPattern: nil, hint: "说再见")
            ]
        )

        // Units 5-9 with simplified scripts for brevity
        for unitId in 5...9 {
            scripts[unitId] = createSimplifiedScript(unitId: unitId)
        }
    }

    private func createSimplifiedScript(unitId: Int) -> DialogueScript {
        let titles = [
            5: "Happy Birthday",
            6: "A Day Out",
            7: "Let's Play",
            8: "At Home",
            9: "Happy Holidays"
        ]

        let title = titles[unitId] ?? "Unit \(unitId)"

        return DialogueScript(
            unit: unitId,
            title: title,
            opening: [
                DialogueRound(round: 0, speaker: "sam", text: "Hello! Welcome to \(title)! How are you?", expectedResponse: "I'm good", keyVocabulary: nil, keyPattern: nil, hint: nil),
                DialogueRound(round: 1, speaker: "sam", text: "Great! Let's learn together! Ready?", expectedResponse: "Yes, ready", keyVocabulary: nil, keyPattern: nil, hint: nil)
            ],
            rounds: [
                DialogueRound(round: 2, speaker: "sam", text: "What's your name?", expectedResponse: "I'm [name]", keyVocabulary: nil, keyPattern: "I'm [name]", hint: "回答你的名字"),
                DialogueRound(round: 3, speaker: "sam", text: "How old are you?", expectedResponse: "I'm [age]", keyVocabulary: nil, keyPattern: "I'm [number]", hint: "回答年龄"),
                DialogueRound(round: 4, speaker: "sam", text: "Do you like \(title.lowercased())?", expectedResponse: "Yes, I do", keyVocabulary: nil, keyPattern: "Yes, I do", hint: "喜欢吗"),
                DialogueRound(round: 5, speaker: "sam", text: "What color do you like?", expectedResponse: "I like [color]", keyVocabulary: nil, keyPattern: "I like [color]", hint: "喜欢的颜色"),
                DialogueRound(round: 6, speaker: "sam", text: "Can you count to five?", expectedResponse: "One, two, three, four, five", keyVocabulary: nil, keyPattern: nil, hint: "数到五"),
                DialogueRound(round: 7, speaker: "sam", text: "How are you feeling?", expectedResponse: "I'm happy/good", keyVocabulary: nil, keyPattern: "I'm [feeling]", hint: "感觉如何"),
                DialogueRound(round: 8, speaker: "sam", text: "What's your favorite animal?", expectedResponse: "I like [animal]", keyVocabulary: nil, keyPattern: "I like [animal]", hint: "喜欢的动物"),
                DialogueRound(round: 9, speaker: "sam", text: "Can you say 'Hello'?", expectedResponse: "Hello", keyVocabulary: nil, keyPattern: nil, hint: "说Hello"),
                DialogueRound(round: 10, speaker: "sam", text: "Say 'Thank you'!", expectedResponse: "Thank you", keyVocabulary: nil, keyPattern: nil, hint: "说谢谢"),
                DialogueRound(round: 11, speaker: "sam", text: "What's this?", expectedResponse: "It's a [item]", keyVocabulary: nil, keyPattern: "It's a [item]", hint: "这是什么"),
                DialogueRound(round: 12, speaker: "sam", text: "Are you ready to play?", expectedResponse: "Yes, I am", keyVocabulary: nil, keyPattern: "Yes, I am", hint: "准备好了吗"),
                DialogueRound(round: 13, speaker: "sam", text: "Great job! You're learning so fast!", expectedResponse: "Thank you", keyVocabulary: nil, keyPattern: nil, hint: "谢谢"),
                DialogueRound(round: 14, speaker: "sam", text: "Bye bye! See you next time! 👋", expectedResponse: "Bye", keyVocabulary: nil, keyPattern: nil, hint: "说再见")
            ]
        )
    }
}
