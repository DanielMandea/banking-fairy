# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'VirtualAssistantforiOSwithWatsonBOKEI' do
    pod 'BMSCore', '~> 2.0'


    # Comment this line if you're not using Swift and don't want to use dynamic frameworks

    use_frameworks!

    pod 'MessageKit'
    pod 'NVActivityIndicatorView'
    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'HEREMapsStarter'

    post_install do |installer|
        installer.pods_project.targets.each do |target|
            if ['SwiftCloudant'].include? target.name
                target.build_configurations.each do |config|
                    config.build_settings['SWIFT_VERSION'] = '3.2'
                end
            end
        end
    end
    # Pods for VirtualAssistantforiOSwithWatsonBOKEI
    target 'VirtualAssistantforiOSwithWatsonBOKEITests' do
        inherit! :search_paths
        # Pods for testing
    end

    target 'VirtualAssistantforiOSwithWatsonBOKEIUITests' do
        inherit! :search_paths
        # Pods for testing
    end

end
