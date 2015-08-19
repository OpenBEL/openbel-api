require 'bel'

module OpenBEL
  module Transform

    class AnnotationGroupingTransform

      ExperimentContext = ::BEL::Model::ExperimentContext

      def transform_evidence!(evidence)
        experiment_context = evidence.experiment_context
        if experiment_context != nil
          evidence.experiment_context = ExperimentContext.new(
            experiment_context.group_by { |annotation|
              annotation[:name]
            }.values.map do |grouped_annotation|
              {
                :name  => grouped_annotation.first[:name],
                :value => grouped_annotation.flat_map { |annotation|
                  annotation[:value]
                },
                :uri   => grouped_annotation.flat_map { |annotation|
                  annotation[:uri]
                }
              }
            end
          )
        end
      end
    end

  end
end
