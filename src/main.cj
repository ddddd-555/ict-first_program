// teating 
package chat

import std.io.*
import std.collection.*
//import chat.LLM
//import chat.WordManager

class Word {
    public let word: String
    public let meaning: String

    public init(word: String, meaning: String) {
        this.word = word
        this.meaning = meaning
    }
}

main() {
    // 初始化单词管理器
    let wordManager = WordManager("my_words.txt")
    
    // 初始化AI助手
    let aiAssistant = LLM(
        url: 'https://api.siliconflow.cn/v1/chat/completions',
        key: 'sk-ujrvulmnsdiolckgtjklhqbwbkfudgeglrkxxbzljagbtrnk',
        model: 'deepseek-ai/DeepSeek-V3',
        memory: false
    )
    
    // 设置AI助手的学习风格
    aiAssistant.preset('你是一个专业的英语学习助手，请用简洁明了的方式帮助用户学习英语单词')
    
    println("=== 英语单词记忆助手 ===")
    println("当前单词库中有 ${wordManager.getWordCount()} 个单词")
    
    while (true) {
        println("\n请选择功能:")
        println("1. 添加新单词")
        println("2. 随机抽背单词") 
        println("3. 查询单词详情（近义词/易混淆词等）")
        println("4. 显示单词数量")
        println("5. 清空单词库")
        println("6. 退出")
        print("请输入选项 (1-6): ")
        
        let choice = readln()
        
        match (choice) {
            case "1" => addWordMode(wordManager)
            case "2" => quizMode(wordManager, aiAssistant)
            case "3" => queryMode(aiAssistant)
            case "4" => showWordCount(wordManager)
            case "5" => clearWords(wordManager)
            case "6" => break
            case _ => println("无效选项，请重新输入")
        }
    }
    
    println("\n感谢使用英语单词记忆助手!")
}

// 添加单词模式
func addWordMode(wordManager: WordManager) {
    println("\n--- 添加新单词 ---")
    print("请输入英文单词: ")
    let word = readln()
    
    if (word.isEmpty()) {
        println("单词不能为空")
        return
    }
    
    print("请输入中文释义: ")
    let meaning = readln()
    
    if (meaning.isEmpty()) {
        println("释义不能为空")
        return
    }
    
    wordManager.addWord(word, meaning)
    println("✓ 单词 '${word}' 已成功添加到单词库！")
}

// 抽背模式
func quizMode(wordManager: WordManager, aiAssistant: LLM) {
    println("\n--- 单词抽背测试 ---")
    let wordCount = wordManager.getWordCount()
    
    if (wordCount == 0) {
        println("单词库为空，请先添加单词")
        return
    }
    
    print("请输入要测试的单词数量 (当前共有 ${wordCount} 个单词): ")
    let countInput = readln()
    let count = if (countInput.isEmpty()) { 5 } else { Int64(countInput).getOrDefault(5) }
    
    let words = wordManager.getRandomWords(count)
    var correctCount = 0
    var wrongWords = ArrayList<String>()
    
    println("开始测试，共 ${words.size} 个单词...")
    
    for ((i, wordObj) in words.enumerate()) {
        println("\n--- 第 ${i+1}/${words.size} 题 ---")
        println("英文单词: ${wordObj.word}")
        print("请输入中文释义: ")
        let answer = readln()
        
        if (answer == wordObj.meaning) {
            println("✓ 正确！")
            correctCount = correctCount + 1
        } else {
            println("✗ 错误！正确答案是: ${wordObj.meaning}")
            wrongWords.add(wordObj.word)
        }
    }
    
    println("\n=== 测试结果 ===")
    println("正确: ${correctCount}/${words.size}")
    println("正确率: ${(correctCount * 100 / words.size)}%")
    
    // 如果有错题，提供AI解析-----------------------------需要调用llm
    if (!wrongWords.isEmpty()) {
        println("\n需要重点复习的单词: ${wrongWords}")
        print("是否让AI助手解析这些单词?(y/n): ")
        let helpChoice = readln()
        if (helpChoice == "y" || helpChoice == "Y") {
            for (word in wrongWords) {
                println("\n--- ${word} 的解析 ---")

                let explanation = aiAssistant.chat("请用简单中文解释单词 '${word}' 并给出2个例句")
                //-- 0 方法---
                println(explanation)
            }
        }
    }
}

// 查询模式
func queryMode(aiAssistant: LLM) {
    println("\n--- 单词智能查询 ---")
    print("请输入要查询的单词: ")
    let word = readln()
    
    if (word.isEmpty()) {
        println("单词不能为空")
        return
    }
    
    println("\n请选择查询类型:")
    println("1. 详细释义和例句")
    println("2. 近义词查询") 
    println("3. 易混淆词辨析")
    println("4. 反义词查询")
    println("5. 词根词缀分析")
    print("请输入选项 (1-5): ")
    
    let choice = readln()
    
    println("\n=== 查询结果 ===")
    match (choice) {
        case "1" => 
            let prompt = "请详细解释单词 '${word}':包括中文释义、词性、用法,并提供3个典型例句"
            println(aiAssistant.chat(prompt))
        
        case "2" => 
            let prompt = "请给出单词 '${word}' 的3个常用近义词,并简要说明每个近义词的细微差别"
            println(aiAssistant.chat(prompt))
        
        case "3" => 
            let prompt = "请列出与单词 '${word}' 最容易混淆的2个单词,并详细说明它们之间的区别"
            println(aiAssistant.chat(prompt))
        
        case "4" => 
            let prompt = "请给出单词 '${word}' 的2个常用反义词,并说明使用场景"
            println(aiAssistant.chat(prompt))
        
        case "5" => 
            let prompt = "请分析单词 '${word}' 的词根词缀构成,并给出同词根的2个相关单词"
            println(aiAssistant.chat(prompt))
        
        case _ => println("无效选项")
    }
}

// 显示单词数量
func showWordCount(wordManager: WordManager) {
    let count = wordManager.getWordCount()
    println("\n当前单词库中共有 ${count} 个单词")
}

// 清空单词库
func clearWords(wordManager: WordManager) {
    print("确定要清空所有单词吗？此操作不可撤销！(输入'确认清空'继续): ")
    let confirm = readln()
    if (confirm == "确认清空") {
        wordManager.clearAllWords()
        println("单词库已清空")
    } else {
        println("操作已取消")
    }
}
