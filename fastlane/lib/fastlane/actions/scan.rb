module Fastlane
  module Actions
    module SharedValues
      SCAN_DERIVED_DATA_PATH = :SCAN_DERIVED_DATA_PATH
      SCAN_GENERATED_PLIST_FILE = :SCAN_GENERATED_PLIST_FILE
      SCAN_GENERATED_PLIST_FILES = :SCAN_GENERATED_PLIST_FILES
    end

    class ScanAction < Action
      def self.run(values)
        require 'scan'

        begin
          Scan.config = values # we set this here to auto-detect missing values, which we need later on
          unless values[:derived_data_path].to_s.empty?
            plist_files_before = test_summary_filenames(values[:derived_data_path])
            Scan.config[:destination] = nil # we have to do this, as otherwise a warning is shown to the user to not set this value
          end

          FastlaneCore::UpdateChecker.start_looking_for_update('scan') unless Helper.is_test?

          Scan::Manager.new.work(values)

          return true
        rescue => ex
          if values[:fail_build]
            raise ex
          end
        ensure
          unless values[:derived_data_path].to_s.empty?
            Actions.lane_context[SharedValues::SCAN_DERIVED_DATA_PATH] = values[:derived_data_path]
            plist_files_after = test_summary_filenames(values[:derived_data_path])
            all_test_summaries = (plist_files_after - plist_files_before)
            Actions.lane_context[SharedValues::SCAN_GENERATED_PLIST_FILES] = all_test_summaries
            Actions.lane_context[SharedValues::SCAN_GENERATED_PLIST_FILE] = all_test_summaries.last
          end

          FastlaneCore::UpdateChecker.show_update_status('scan', Scan::VERSION)
        end
      end

      def self.description
        "Easily run tests of your iOS app using `scan`"
      end

      def self.details
        "More information: https://github.com/fastlane/fastlane/tree/master/scan"
      end

      def self.author
        "KrauseFx"
      end

      def self.available_options
        require 'scan'

        FastlaneCore::CommanderGenerator.new.generate(Scan::Options.available_options) + [
          FastlaneCore::ConfigItem.new(key: :fail_build,
                                       env_name: "SCAN_FAIL_BUILD",
                                       description: "Should this step stop the build if the tests fail? Set this to false if you're using trainer",
                                       default_value: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include? platform
      end
      
      private
      
      def self.test_summary_filenames(derived_data_path)
        Dir["#{derived_data_path}/**/Logs/Test/*TestSummaries.plist"]
      end
    end
  end
end
