module ImagesImport
  def img_src(filepath)
    img_map = Native(`webpackImagesMap`)
    img_map["./#{filepath}"]
  end
end