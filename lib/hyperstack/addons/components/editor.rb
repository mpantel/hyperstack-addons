class Editor < Base::Component
  param :value, default: ""
  param :editor_type, default: :trix # [:trix , :sun]
  param :placeholder, default: ''

  fires :blur

  render do
    case editor_type.to_sym
    when :trix
      SPAN do
        TrixEditor(value: value.to_s, className: "input-sm",placeholder: placeholder.to_s)
      end.on(:blur) { |e| blur! e.target.value }
    else # :sun
      # http://suneditor.com/sample/html/options.html
      # https://github.com/mkhstar/suneditor-react
      SunEditor(defaultValue: value.to_s,
                placeholder: placeholder.to_s,
                #toolbarWidth: "50px",
                # width: (Hyperstack.env.test? ? "500px" : "800px"),
                # minWidth: "550px",
								# maxWidth: "1280px",
                height: "200px",
                # minHeight: "150px",
                # maxHeight: "250px",
                setOptions: `{
                             // height: 200,
                              buttonList: [
		[
			"bold",
			"underline",
			"italic",
			"strike",
			"subscript",
			"superscript"],
     ["fontSize",
			"formatBlock",
			"blockquote",
			"fontColor",
			"hiliteColor",
			"textStyle",
			"removeFormat"],
 '/', // Line break
			["outdent",
			"indent",
			"align",
			"horizontalRule",
			"list",
			"lineHeight",
			"table",
			"link"],
			["fullScreen",
			"showBlocks",
			"codeView"],
      ["undo",
			"redo",
		]
	]
      }`,
                onBlur: lambda { |e, c| blur! c })
    end
  end
end
