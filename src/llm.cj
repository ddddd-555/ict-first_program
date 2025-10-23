// 本示例演示访问 DeepSeek 大模型
package chat
import std.collection.*
import std.io.StringReader
import stdx.encoding.json.*
import stdx.net.http.*
import stdx.net.tls.*

// AI 对话中的三类角色
enum Role <: ToString {
    I | AI | System
    public func toString() {
        match (this) {
            case I => 'user'
            case AI => 'assistant'
            case System => 'system'
        }
    }
}

// 用 ArrayList 记录历史对话，扩展两个工具函数
extend ArrayList<String> {
    func add(role: Role, content: String) {
        '{"role":"${role}","content":${JsonString(content)}}' |> add
    }

    func literal() {
        (this |> reduce { a, b =>
            a + ',' + b
        } ) ?? '' // ?? 相当于简化版的 getOrDefault
    }
}

class LLM {
    let client: Client
    let history = ArrayList<String>()
    public LLM(let url!: String, let key!: String, let model!: String,
        var memory!: Bool = false) {
        var config = TlsClientConfig()
        config.verifyMode = TrustAll
        client = ClientBuilder()
            .tlsConfig(config)
            // AI 服务响应有时候比较慢，这里设置为无限等待
            .readTimeout(Duration.Max)
            .build()
    }

    func send(input: String, stream!: Bool = false) {
        if (!memory) {
            history.clear()
        }
        history.add(I, input)
        let content = '''
        { "model":"${model}",
          "messages":[${history.literal()}],
          "stream":${stream} }'''

        let request = HttpRequestBuilder()
            .url(url)
            .header('Authorization', 'Bearer ${key}')
            .header('Content-Type', 'application/json')
            .header('Accept', if (stream) {
                'text/event-stream'
            } else {
                'application/json'
            })
            .body(content)
            .post()
            .build()
        client.send(request)
    }

    func parse(text: String, stream!: Bool = false) {
        let json = JsonValue.fromStr(text).asObject()
        let choices = json.getFields()['choices'].asArray()
        // 流式和非流式情况下，这个字段名称不同
        let key = if (stream) { 'delta' } else { 'message' }
        let message = choices[0].asObject().getFields()[key].asObject()
        let content = message.getFields()['content'].asString().getValue()
        return content
    }

    // 流式对话
    public func chats(input: String, task!: (String) -> Unit = {o => print(o)}) {
        let response = send(input, stream: true)
        let output = StringBuilder()
        let buffer = Array<Byte>(1024 * 8, repeat: 0)
        var length = response.body.read(buffer)
        while (length != 0) {
            let text = String.fromUtf8(buffer[..length])
            const INDEX = 6
            for (line in text.split('\n', removeEmpty: true)) {
                if (line.size > INDEX && line[INDEX] == b'{') {
                    let json = line[INDEX..line.size]
                    let slice = parse(json, stream: true)
                    output.append(slice)
                    task(slice)
                }
            }
            length = response.body.read(buffer)
        }
        history.add(AI, output.toString())
    }

    // 非流式
    public func chat(input: String) {
        let response = send(input)
        let output = StringReader(response.body).readToEnd() |> parse
        history.add(AI, output)
        return output
    }

    // 角色预设或加载历史对话
    public func preset(content: String, role!: Role = System) {
        history.add(role, content)
        show_history()
        memory = true
    }

    public func switchStyle(styleName: String) {
        if (styleName.isEmpty()) {
            println ("输入有误")
            return
        }
        history.add(System, styleName)
        println('\n----------\n')
        println("切换至${styleName}风格")
        println('\n----------\n')
        show_history()
        memory = true
    }

    public func show_history(){
        println("历史记录：${history.size}")
    }

    public func reset() {
        history.clear()
    }

    public func show_style(){
        println("history")
        for (i in 0..history.size){
            println("${i}: ${history[i]}")
        }
        show_history()
    }

    

}