/*
智谱AI翻译
*/

#Include lib_json.ahk   	;引入json解析文件

global TransEdit,transEditHwnd,transGuiHwnd, NativeString
global zhipuApiKey := ""

llmTransInit:
	global zhipuApiKey  ; 确保在函数内部可以修改全局变量
	; 从配置文件中读取API密钥
	if (CLSets.TTranslate.zhipuApiKey != "")
	{
		zhipuApiKey := CLSets.TTranslate.zhipuApiKey
	}
return

llmTranslate(ss){
	global zhipuApiKey  ; 在函数内声明使用全局变量
	
	; 如果zhipuApiKey为空，尝试重新从配置读取
	if (zhipuApiKey = "" && CLSets.TTranslate.zhipuApiKey != "") {
		zhipuApiKey := CLSets.TTranslate.zhipuApiKey
	}
	
	if (!ss)
		return
	; 检查API密钥
	if (zhipuApiKey = "") {
		MsgBox, % lang_llm_needKey
		return
	}
	; 检测语言,简单判断是否包含中文字符
	hasChinese := RegExMatch(ss, "[\x{4e00}-\x{9fa5}]")

	; 准备请求体
	requestBody := {}
	requestBody.model := "glm-4-flash"
	requestBody.messages := [{role: "user", content: (hasChinese ? "将以下文本翻译成英文：" : "将以下文本翻译成中文：") . ss}]

	; 创建JSONStr
	jsonString := JSON.Dump(requestBody)

	; 创建HTTP请求
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("POST", "https://open.bigmodel.cn/api/paas/v4/chat/completions", false)
	whr.SetRequestHeader("Content-Type", "application/json")
	whr.SetRequestHeader("Authorization", "Bearer " . zhipuApiKey)

	; 初始化显示文本
	MsgBoxStr := ""

	; 发送请求并处理响应
	try {
		whr.Send(jsonString)
		responseStr := whr.ResponseText

		; 替换特殊字符
		responseStr := RegExReplace(responseStr, "[\x00-\x1F\x7F]", "")  ; 移除控制字符
		responseStr := StrReplace(responseStr, "*", """")  ; 替换星号为引号
		responseStr := StrReplace(responseStr, "1]", "]")  ; 修正数组结束符

		response := JSON.Load(responseStr)
		translation := response.choices[1].message.content

		; 构建显示文本
		MsgBoxStr := ss . "`t`r`n`r`n" . lang_llm_trans . "`r`n" . translation
	} catch e {
		MsgBoxStr := e.what = "" ? lang_yd_errorNoNet : "解析错误: " . e.message
	}

	; 显示GUI
	DetectHiddenWindows, On
	WinGet, ifGuiExistButHide, Count, ahk_id %transGuiHwnd%
	if(ifGuiExistButHide)
	{
		ControlSetText, , %MsgBoxStr%, ahk_id %transEditHwnd%
		ControlFocus, , ahk_id %transEditHwnd%
		WinShow, ahk_id %transGuiHwnd%
	}
	else
	{
		Gui, new, +HwndtransGuiHwnd , %lang_llm_name%
		Gui, +AlwaysOnTop -Border +Caption -Disabled -LastFound -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme -ToolWindow
		
		Gui, Font, s10 w400, Microsoft YaHei UI
		Gui, Font, s10 w400, 微软雅黑
		gui, Add, Button, x-40 y-40 Default, OK

		
		Gui, Add, Edit, x-2 y0 w504 h405 vTransEdit HwndtransEditHwnd -WantReturn -VScroll , %MsgBoxStr%
		Gui, Color, ffffff, fefefe
		Gui, +LastFound
		WinSet, TransColor, ffffff 210
		Gui, Show, Center w500 h402, %lang_llm_name%
		ControlFocus, , ahk_id %transEditHwnd%
	}

	; 更新显示内容
	ControlSetText, , %MsgBoxStr%, ahk_id %transEditHwnd%
	ControlFocus, , ahk_id %transEditHwnd%
	SetTimer, setTransActive, 50
}