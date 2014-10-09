module OpenBEL::Storage
  module Storage

    def triples(subject, predicate, object, options={})
      fail NotImplementedError, "#{__method__} is not implemented"
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
