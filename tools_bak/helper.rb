require 'pathname'

module Kernel

  def chdir_to_root!
    Dir.chdir (Pathname(File.dirname(File.expand_path(__FILE__))) + '..')
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
