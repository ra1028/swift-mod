Pod::Spec.new do |spec|
    spec.name = 'swift-mod'
    spec.version  = `cat .version`
    spec.author = { 'ra1028' => 'r.fe51028.r@gmail.com' }
    spec.homepage = 'https://github.com/ra1028/swift-mod'
    spec.summary = 'A tool for Swift code modification intermediating between code generation and formatting.'
    spec.source = { :git => 'https://github.com/ra1028/swift-mod.git', :tag => spec.version.to_s }
    spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
    spec.source = { http: "#{spec.homepage}/releases/download/#{spec.version}/swift-mod.zip" }
    spec.preserve_paths = '*'
    spec.exclude_files  = '**/file.zip'
end
