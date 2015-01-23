require 'popen4'

module OpenBEL
  module Tools
    def self.sh(*args)
      cmd = args.join(' ').squeeze(' ')
      lines_out = []
      ret = POpen4::popen4(cmd) do |out, err, _|
        out.each do |line|
          puts line
          lines_out << line
        end
        err.each do |line|
          puts line
        end
      end
      [ret.exitstatus, lines_out.size == 1 ? lines_out.first : lines_out]
    end

    def self.sh!(*args)
      ret = self.sh(*args).first
      exit ret if ret.nonzero?
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
