require "xcodeproj"

root = File.expand_path("..", __dir__)
project_path = File.join(root, "ExpenseTracker.xcodeproj")
project = Xcodeproj::Project.new(project_path)

app = project.new_target(:application, "ExpenseTracker", :ios, "17.0")
tests = project.new_target(:unit_test_bundle, "ExpenseTrackerTests", :ios, "17.0")
tests.add_dependency(app)

def add_tree(project_group, disk_path, target)
  Dir.children(disk_path).sort.each do |name|
    next if name.start_with?(".")
    full_path = File.join(disk_path, name)
    if File.directory?(full_path) && name.end_with?(".xcassets")
      reference = project_group.new_file(full_path)
      target.resources_build_phase.add_file_reference(reference)
    elsif File.directory?(full_path)
      add_tree(project_group.new_group(name), full_path, target)
    elsif name.end_with?(".swift")
      reference = project_group.new_file(full_path)
      target.source_build_phase.add_file_reference(reference)
    end
  end
end

app_group = project.main_group.new_group("ExpenseTracker", "ExpenseTracker")
test_group = project.main_group.new_group("ExpenseTrackerTests", "ExpenseTrackerTests")
add_tree(app_group, File.join(root, "ExpenseTracker"), app)
add_tree(test_group, File.join(root, "ExpenseTrackerTests"), tests)

app.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.local.ExpenseTracker"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["INFOPLIST_FILE"] = "ExpenseTracker/Info.plist"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
  config.build_settings["SWIFT_VERSION"] = "5.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
end

tests.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.local.ExpenseTrackerTests"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["SWIFT_VERSION"] = "5.0"
  config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/ExpenseTracker.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ExpenseTracker"
  config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end

project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.save_as(project_path, "ExpenseTracker", true)
