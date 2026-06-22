require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'lidar-sensor'
  s.version        = package['version']
  s.summary        = package['description']
  s.homepage       = 'https://github.com/runble6/putt-ai'
  s.license        = 'MIT'
  s.authors        = { 'PuttAI' => 'sendy0317@wikey.co.kr' }
  s.platforms      = { :ios => '14.0' }
  s.source         = { :git => '' }
  s.source_files   = '*.{swift}'
  s.dependency 'ExpoModulesCore'
  s.framework      = 'ARKit'
end
