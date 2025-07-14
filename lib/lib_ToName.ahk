/*
智谱AI命名变量
*/

#Include lib_json.ahk   	;引入json解析文件

global TransEdit,transEditHwnd,transGuiHwnd, NativeString
global zhipuApiKey := ""
global zhipuModel := "glm-4-flash-250414"  ; 默认模型

; llmTransInitName:
; 	global zhipuApiKey  ; 确保在函数内部可以修改全局变量
; 	global zhipuModel
; 	; 从配置文件中读取API密钥和模型
; 	if (CLSets.TTranslate.zhipuApiKey != "")
; 	{
; 		zhipuApiKey := CLSets.TTranslate.zhipuApiKey
; 	}
; 	if (CLSets.TTranslate.model != "")
; 	{
; 		zhipuModel := CLSets.TTranslate.model
; 	}
return

llmToName(ss){
	global zhipuApiKey  ; 在函数内声明使用全局变量
	global zhipuModel

	; 如果zhipuApiKey为空，尝试重新从配置读取
	if (zhipuApiKey = "" && CLSets.TTranslate.zhipuApiKey != "") {
		zhipuApiKey := CLSets.TTranslate.zhipuApiKey
	}
	if (zhipuModel = "" && CLSets.TTranslate.model != "") {
		zhipuModel := CLSets.TTranslate.model
	}

	if (!ss)
		return
	; 检查API密钥
	if (zhipuApiKey = "") {
		MsgBox, % lang_llm_needKey
		return
	}

	; 变量大驼峰 小驼峰 下划线 横线 常量
	; 修改 prompt，要求 AI 输出五种命名风格
	prompt := "请将以下内容用于变量命名，并分别给出大驼峰、小驼峰、下划线、横线、常量（全大写下划线分隔）五种风格的英文变量名建议 """ ss """"

	; 准备请求体
	requestBody := {}
	requestBody.model := zhipuModel
	requestBody.messages := [{role: "user", content: prompt}]

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

		; 优先尝试解析JSON，获取choices[1].message.content
		translation := ""
		try {
			response := JSON.Load(responseStr)
			if (IsObject(response) && IsObject(response.choices) && response.choices[1].message.content != "") {
				translation := response.choices[1].message.content
			} else {
				translation := responseStr
			}
		} catch {
			translation := responseStr
		}

		; 优化换行显示
		translation := StrReplace(translation, "`r`n", "`r`n") ; 兼容已有换行
		translation := StrReplace(translation, "`n", "`r`n")
		translation := StrReplace(translation, "\r\n", "`r`n")
		translation := StrReplace(translation, "\n", "`r`n")

		; 构建显示文本，突出五种命名风格
		MsgBoxStr := ss . "`t`r`n`r`n" . lang_llm_toName . "`r`n" . translation
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