require 'active_support/core_ext'

module Elastictastic
  CancelBulkOperation = Class.new(StandardError)

  autoload :Configuration, 'elastictastic/configuration'
  autoload :Document, 'elastictastic/document'
  autoload :Field, 'elastictastic/field'
  autoload :IndividualPersister, 'elastictastic/individual_persister'
  autoload :NetHttpTransport, 'elastictastic/net_http_transport'
  autoload :Persistence, 'elastictastic/persistence'
  autoload :Requests, 'elastictastic/requests'
  autoload :Resource, 'elastictastic/resource'
  autoload :Scope, 'elastictastic/scope'
  autoload :Scoped, 'elastictastic/scoped'
  autoload :Search, 'elastictastic/search'
  autoload :Util, 'elastictastic/util'

  class <<self
    attr_writer :configuration

    def config
      @config ||= Elastictastic::Configuration.new
    end

    def transport=(transport)
      Thread.current['Elastictastic::transport'] = transport
    end

    def transport
      Thread.current['Elastictastic::transport'] ||= new_transport
    end

    def persister=(persister)
      Thread.current['Elastictastic::persister'] = persister
    end

    def persister
      Thread.current['Elastictastic::persister'] ||=
        Elastictastic::IndividualPersister.instance
    end

    def bulk
      original_persister = self.persister
      begin
        self.persister = Elastictastic::BulkPersister.new
        yield
        self.persister.flush
      rescue Elastictastic::CancelBulkOperation
        # Nothing to see here...
      ensure
        self.persister = original_persister
      end
    end

    private

    def new_transport
      transport_class = const_get("#{config.transport.camelize}Transport")
      transport_class.new(config)
    end
  end
end
