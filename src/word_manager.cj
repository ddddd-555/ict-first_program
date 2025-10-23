// 单词管理模块：仅保留内存中单词存储、计数及随机抽词
package chat

import std.collection.{ArrayList, HashSet}
import std.io.*
import std.random.Random

// 单词管理器：仅内存操作
class WordManager {

    private let filePath: String  // 单词存储文件路径（如"my_words.txt"）

    // 内存存储核心：用ArrayList保存所有单词
    private let wordList: ArrayList<Word>

    // 构造函数：初始化内存单词列表
    public init(filePath: String) {
        this.wordList = ArrayList<Word>()
        this.filePath = filePath

    /**
     * 1. 添加单词：直接存入内存列表
     * @param word 英文单词
     * @param meaning 中文释义
     * @return 布尔值：true=添加成功，false=添加失败
     */
    public func addWord(word: String, meaning: String): Bool {
        let trimmedWord = word
        let trimmedMeaning = meaning
        
        if (trimmedWord.isEmpty() || trimmedMeaning.isEmpty()) {
            println("单词或释义不能为空，添加失败")
            return false
        }

        for (existingWord in wordList) {
            if (existingWord.word.equalsIgnoreCase(trimmedWord)) {
                println("单词 '${trimmedWord}' 已存在，添加失败")
                return false
            }
        }

        wordList.add(Word(trimmedWord, trimmedMeaning))
        println("单词 '${trimmedWord}' 已添加到内存库")
        return true
    }

    /**
     * 2. 获取单词总数：直接读取内存列表长度
     * @return 内存中存储的单词数量
     */
    public func getWordCount(): Int64{
        return wordList.size()
    }

    /**
     * 3. 随机抽取单词：均匀抽样，无重复
     * @param count 抽取数量
     * @return 随机单词列表
     */
    public func getRandomWords(count: Int): ArrayList<Word> {
        let total = wordList.size()
        let result = ArrayList<Word>()

        if (total == 0 || count <= 0) {
            println("无可用单词或抽取数量非法，返回空列表")
            return result
        }

        let actualCount = if (count > total) { total } else { count }
        let random = Random.init()
        let usedIndexes = HashSet<Int>()

        while (usedIndexes.size() < actualCount) {
            let index = random.nextInt(0, total - 1)
            if (!usedIndexes.contains(index)) {
                usedIndexes.add(index)
                result.add(wordList.get(index))
            }
        }
        return result
    }

    /**
     * 4. 清空单词库：直接清空内存列表
     */
    public func clearAllWords() {
        wordList.clear()
        println("内存单词库已清空")
    }

    /**
     * 5. 查看所有单词：遍历内存列表
     */
    public func showAllWords() {
        let total = wordList.size()
        if (total == 0) {
            println("内存单词库为空")
            return
        }
        println("\n内存中所有单词（共 ${total} 个）：")
        for ((i, word) in wordList.enumerate()) {
            println("${i+1}. ${word.word} → ${word.meaning}")
        }
    }
}