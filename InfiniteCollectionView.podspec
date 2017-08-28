Pod::Spec.new do |s|
  s.name         = "InfiniteCollectionView"
  s.version      = "1.3.2"
  s.summary      = "Infinite Scrolling Using UICollectionView."
  s.homepage     = "https://github.com/xperi/InfiniteCollectionView"
  s.screenshots  = "https://github.com/xperi/InfiniteCollectionView/wiki/images/sample1.gif"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "xperi" => "xperi@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/xperi/InfiniteCollectionView.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/*.{h,swift}"
  s.frameworks = "UIKit"
  s.requires_arc = true
end
