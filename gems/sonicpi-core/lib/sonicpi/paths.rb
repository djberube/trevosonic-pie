#--
# This file is part of Sonic Pi: http://sonic-pi.net
# Full project source: https://github.com/sonic-pi-net/sonic-pi
# License: https://github.com/sonic-pi-net/sonic-pi/blob/main/LICENSE.md
#
# Copyright 2021 by Sam Aaron (http://sam.aaron.name).
# All rights reserved.
#
# Permission is granted for use, copying, modification, and
# distribution of modified versions of this work as long as this
# notice is included.
#++

# Simplified Paths module for sonicpi-core gem
# This provides minimal path functionality needed for the core library
# For full IDE paths, see the application-specific paths module

module SonicPi
  module Paths
    class << self
      # Allow configuration of paths
      attr_accessor :home_dir_path, :log_path, :samples_path, :buffers_path, :synthdef_path

      def user_dir
        return File.expand_path(ENV["SONIC_PI_HOME"]) if ENV["SONIC_PI_HOME"]

        # Figure out the user's home directory
        case os
        when :windows
          return File.expand_path(ENV["USERPROFILE"]) if ENV["USERPROFILE"]
          home_drive = ENV["HOMEDRIVE"]
          home_path = ENV["HOMEPATH"]
          return File.absolute_path("#{home_drive}/#{home_path}") if home_drive and home_path
          return File.expand_path(ENV["HOME"]) if ENV["HOME"]
          return File.expand_path(Dir.home)
        else
          return File.expand_path(ENV["HOME"]) if ENV["HOME"]
          return File.expand_path(Dir.home)
        end
      end

      def home_dir_path
        @home_dir_path ||= File.absolute_path("#{user_dir}/.sonic-pi/")
      end

      def project_path
        File.expand_path("#{home_dir_path}/store/default/")
      end

      def log_path
        @log_path ||= File.absolute_path("#{home_dir_path}/log")
      end

      def scsynth_log_path
        File.absolute_path("#{log_path}/scsynth.log")
      end

      def tau_log_path
        File.absolute_path("#{log_path}/tau.log")
      end

      def spider_log_path
        File.absolute_path("#{log_path}/spider.log")
      end

      def daemon_log_path
        File.absolute_path("#{log_path}/daemon.log")
      end

      # Asset paths - these can be overridden
      def samples_path
        @samples_path ||= File.absolute_path("#{default_asset_root}/samples")
      end

      def buffers_path
        @buffers_path ||= File.absolute_path("#{default_asset_root}/buffers")
      end

      def synthdef_path
        @synthdef_path ||= File.absolute_path("#{default_asset_root}/synthdefs/compiled")
      end

      def cached_samples_path
        File.absolute_path("#{project_path}/cached_samples")
      end

      def os
        case RUBY_PLATFORM
        when /.*linux.*/
          :linux
        when /.*darwin.*/
          :macos
        when /.*mingw.*/
          :windows
        else
          raise "Unsupported platform #{RUBY_PLATFORM}"
        end
      end

      private

      def default_asset_root
        # Try to find assets in common locations
        # 1. Check for bundled assets in gem installation
        gem_etc = File.expand_path("../../../../etc", __FILE__)
        return gem_etc if File.directory?(gem_etc)

        # 2. Check for development environment
        dev_etc = File.expand_path("../../../../../etc", __FILE__)
        return dev_etc if File.directory?(dev_etc)

        # 3. Fall back to home directory
        "#{home_dir_path}/assets"
      end
    end
  end
end
