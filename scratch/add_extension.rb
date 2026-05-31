require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Add entitlements file path to Runner configurations
puts "Updating Runner target's CODE_SIGN_ENTITLEMENTS..."
runner_target = project.targets.find { |t| t.name == 'Runner' }
runner_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# Update project-level and Runner target deployment target to 15.0
puts "Updating project and Runner deployment target to 15.0..."
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end
runner_target.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end

# 2. Check if OneSignalNotificationServiceExtension target already exists
ext_target = project.targets.find { |t| t.name == 'OneSignalNotificationServiceExtension' }
if ext_target.nil?
  puts "Creating OneSignalNotificationServiceExtension target..."
  # Create new target
  ext_target = project.new_target(:app_extension, 'OneSignalNotificationServiceExtension', :ios, '15.0')
else
  puts "OneSignalNotificationServiceExtension target already exists, updating configuration..."
end

# 3. Configure target properties
puts "Configuring build settings for OneSignalNotificationServiceExtension..."
ext_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.zbooma.fiveamat.OneSignalNotificationServiceExtension'
  config.build_settings['INFOPLIST_FILE'] = 'OneSignalNotificationServiceExtension/Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'OneSignalNotificationServiceExtension/OneSignalNotificationServiceExtension.entitlements'
  config.build_settings['SDKROOT'] = 'iphoneos'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1' # iPhone only
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
end

# 4. Add the extension folder and files to the project group
puts "Adding files to project group..."
ext_group = project.main_group['OneSignalNotificationServiceExtension']
if ext_group.nil?
  ext_group = project.main_group.new_group('OneSignalNotificationServiceExtension', 'OneSignalNotificationServiceExtension')
end

# Add files to the group (avoid duplicating references if they already exist)
def add_file_to_group_and_target(project, group, target, file_name, is_source = false)
  file_ref = group.files.find { |f| f.path == file_name }
  if file_ref.nil?
    file_ref = group.new_file(file_name)
  end
  
  if is_source
    # Add to compile sources build phase if it's swift/objective-c and not already there
    sources_phase = target.source_build_phase
    unless sources_phase.files.any? { |f| f.file_ref == file_ref }
      sources_phase.add_file_reference(file_ref)
    end
  end
  file_ref
end

swift_file = add_file_to_group_and_target(project, ext_group, ext_target, 'NotificationService.swift', true)
add_file_to_group_and_target(project, ext_group, ext_target, 'Info.plist', false)
add_file_to_group_and_target(project, ext_group, ext_target, 'OneSignalNotificationServiceExtension.entitlements', false)

# 5. Embed the extension in the Main App (Runner) target's Copy Files build phase
puts "Embedding App Extension in Runner target..."
unless runner_target.dependencies.any? { |dep| dep.target == ext_target }
  runner_target.add_dependency(ext_target)
end

# Find or create a "Copy Files" phase for embedding app extensions (plugins)
copy_phase = runner_target.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' || phase.dst_subfolder_spec == '13' }
if copy_phase.nil?
  copy_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
  copy_phase.dst_subfolder_spec = '13'
end

# Add the extension product to the copy phase
product_ref = ext_target.product_reference
unless copy_phase.files.any? { |f| f.file_ref == product_ref }
  build_file = copy_phase.add_file_reference(product_ref)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts "Xcode project updated successfully!"
