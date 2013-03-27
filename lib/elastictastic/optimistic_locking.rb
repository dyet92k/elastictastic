module Elastictastic

  module OptimisticLocking

    extend ActiveSupport::Concern

    module ClassMethods

      def create_or_update(*ids, &block)
        scope = current_scope
        ids.each do |id|
          begin
            new.tap do |instance|
              instance.id = id
              yield instance
            end.create do |e|
              case e
              when nil # chill
              when Elastictastic::ServerError::DocumentAlreadyExistsEngineException,
                Elastictastic::ServerError::DocumentAlreadyExistsException # 0.19+
                scope.update(id, &block)
              else
                raise e
              end
            end
          rescue Elastictastic::CancelSave
            # Do Nothing
          end
        end
      end

      def update(*ids, &block)
        case ids.length
        when 0 then return
        when 1
          id = ids.first
          instance = scoped({}).find_one(id, :preference => '_primary_first')
          return unless instance
          instances = [instance]
        else
          instances = scoped({}).find_many(ids, :preference => '_primary_first')
        end
        instances.each do |instance|
          instance.try_update(current_scope, &block)
        end
      end

      def update_each(&block)
        all.each { |instance| instance.try_update(current_scope, &block) }
      end

    end

    def try_update(scope, &block) #:nodoc:
      yield self
      update do |e|
        case e
        when nil # chill
        when Elastictastic::ServerError::VersionConflictEngineException,
          Elastictastic::ServerError::VersionConflictException # 0.19
          scope.update(id, &block)
        else
          raise e
        end
      end
    rescue Elastictastic::CancelSave
      # Do Nothing
    end

  end

end
