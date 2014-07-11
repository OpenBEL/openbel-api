require 'rack'
require 'sinatra/base'
require 'sinatra/reloader'
require 'docdsl'
require 'cgi'
require 'oj'

APP_ROOT = OpenBEL::Util::path(File.dirname(__FILE__), '..')

require 'app/resources/html'
require 'app/resources/namespace'

module OpenBEL
  module Routes

    # REST API for retrieving namespaces and values.  Provides the following capabilities:
    #
    # * Retrieve namespaces.
    # * Retrieve values for a namespace using the identifier, preferred name, or title.
    # * Retrieve equivalences for one or more values.
    # * Retrieve equivalences in a target namespace for one or more values.
    # * Retrieve orthologs for one or more values.
    # * Retrieve orthologs in a target namespace for one or more values.
    class Namespaces < Base

      RESULT_TYPES = {
        :resource => :all,
        :name => :prefLabel,
        :identifier => :identifier,
        :title => :title
      }

      register Sinatra::DocDsl
      page do
        header ""
        title "OpenBEL Namespaces"
        introduction "API to access namespaces and their values.

                      - [GET /namespaces](#get-namespaces)
                      - [GET /namespaces/:namespace](#get-namespacesnamespace)
                      - [GET /namespaces/:namespace/equivalents?value=...](#get-namespacesnamespaceequivalents)".squeeze(' ')
        configure_renderer do
          self.render_md
        end
      end

      def initialize(app)
        super
        @api = OpenBEL::Settings.namespace_api
      end

      documentation "Retrieve all namespaces.

                     > example: ``curl http://localhost:3000/namespaces``

                     > [try html](/namespaces)
                     ".squeeze(' ') do
        response "**array** of namespace objects",
          [
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset",
              :name => "Affy Probeset",
              :prefix => "affx",
              :type => "http://www.w3.org/2004/02/skos/core#ConceptScheme",
              :links => [
                {
                    :rel => "self",
                    :href => "http://localhost:3000/namespaces/affy-probeset"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/chebi",
              :name => "Chebi",
              :prefix => "chebi",
              :type => "http://www.w3.org/2004/02/skos/core#ConceptScheme",
              :links => [
                {
                    :rel => "self",
                    :href => "http://localhost:3000/namespaces/chebi"
                }
              ]
            }
          ]
        status 200, "One ore more namespace exist"
        status 404, "No namespaces exist"
      end
      get '/namespaces/?' do
        namespaces = @api.find_namespaces

        halt 404 if not namespaces or namespaces.empty?

        render_multiple(request, namespaces.sort { |x,y|
          x.prefLabel.to_s <=> y.prefLabel.to_s
        }, 'All Namespaces')
      end

      documentation "Retrieve a single namespace by prefix or name.

                     > example: ``curl http://localhost:3000/namespaces/hgnc``

                     > [try html](/namespaces/hgnc)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        response "namespace **object**",
          {
            :rdf_uri => "http://www.openbel.org/bel/namespace/hgnc-human-genes",
            :name => "Hgnc Human Genes",
            :prefix => "hgnc",
            :type => "http://www.w3.org/2004/02/skos/core#ConceptScheme",
            :links => [
              {
                :rel => "self",
                :href => "http://localhost:3000/namespaces/hgnc-human-genes"
              }
            ]
          }
        status 200, "One namespace exists for :namespace"
        status 404, "No namespace exists for :namespace"
      end
      get '/namespaces/:namespace/?' do |namespace|
        ns = @api.find_namespace(namespace)

        puts env

        halt 404 unless ns

        status 200
        render_single(request, ns, 'Namespace')
      end

      documentation "Retrieve equivalents for some namespace values.

                     > All equivalents for HGNC:AKT1

                     > example: ``curl http://localhost:3000/namespaces/hgnc/equivalents?value=AKT1``

                     > [try html](/namespaces/hgnc/equivalents?value=AKT1)

                     > Affy Probeset equivalents for HGNC:AKT1

                     > example: ``curl http://localhost:3000/namespaces/hgnc/equivalents?value=AKT1&namespace=affx``

                     > [try html](/namespaces/hgnc/equivalents?value=AKT1&namespace=affx)

                     > Affy Probeset equivalent identifiers for HGNC:AKT1

                     > example: ``curl http://localhost:3000/namespaces/hgnc/equivalents?value=AKT1&namespace=affx&result=identifier``

                     > [try html](/namespaces/hgnc/equivalents?value=AKT1&namespace=affx&result=identifier)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        query_param :value, "a namespace value in the *:namespace* (one or more)"
        query_param :result, "fields returned for equivalents: #{RESULT_TYPES.keys.join(', ')}"
        query_param :namespace, "the target namespace of the equivalents (optional)"
        response "**object** of *value* keys to array of equivalent namespace objects",
          {
            :AKT1 => [
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1564_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1564_at",
                :prefLabel => "1564_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/entrez-gene/207",
                :inScheme => "http://www.openbel.org/bel/namespace/entrez-gene",
                :identifier => "207",
                :prefLabel => "207",
                :title => "v-akt murine thymoma viral oncogene homolog 1"
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/207163_PM_s_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "207163_PM_s_at",
                :prefLabel => "207163_PM_s_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/207163_s_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "207163_s_at",
                :prefLabel => "207163_s_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/swissprot/P31749",
                :inScheme => "http://www.openbel.org/bel/namespace/swissprot",
                :identifier => "Q9BWB6",
                :prefLabel => "AKT1_HUMAN",
                :title => "RAC-alpha serine/threonine-protein kinase"
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/hgnc-human-genes/391",
                :inScheme => "http://www.openbel.org/bel/namespace/hgnc-human-genes",
                :identifier => "391",
                :prefLabel => "AKT1",
                :title => "v-akt murine thymoma viral oncogene homolog 1"
              }
            ]
          }
        status 200, "One namespace exists for :namespace"
        status 404, "No namespace exists for :namespace"
      end
      get '/namespaces/:namespace/equivalents/?' do |namespace|
        halt 400 unless request.params['value']

        values = CGI::parse(env["QUERY_STRING"])['value']
        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        eq_mapping = @api.find_equivalents(namespace, values, options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump eq_mapping
      end

      post '/namespaces/:namespace/equivalents/?' do |namespace|
        halt 400 unless request.media_type == 'application/json'

        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        request.body.rewind
        json_body = JSON.parse request.body.read
        halt 400 unless json_body['values']

        eq_mapping = @api.find_equivalents(namespace, json_body['values'], options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump(eq_mapping)
      end

      documentation "Retrieve orthologs for some namespace values.

                     > All orthologs for HGNC:AKT1

                     > example: ``curl http://localhost:3000/namespaces/hgnc/orthologs?value=AKT1``

                     > [try html](/namespaces/hgnc/orthologs?value=AKT1)

                     > Rgd rat gene ortholog for HGNC:AKT1

                     > example: ``curl http://localhost:3000/namespaces/hgnc/orthologs?value=AKT1&namespace=rgd``

                     > [try html](/namespaces/hgnc/orthologs?value=AKT1&namespace=rgd)

                     > Rgd rat gene ortholog title for HGNC:AKT1

                     > example: ``curl http://localhost:3000/namespaces/hgnc/orthologs?value=AKT1&namespace=rgd&result=name``

                     > [try html](/namespaces/hgnc/orthologs?value=AKT1&namespace=rgd&result=name)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        query_param :value, "a namespace value in the *:namespace* (one or more)"
        query_param :result, "fields returned for orthologs: #{RESULT_TYPES.keys.join(', ')}"
        query_param :namespace, "the target namespace of the orthologs (optional)"
        response "**object** of *value* keys to array of ortholog namespace objects",
          {
            :AKT1 => [
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/100970_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "100970_at",
                :prefLabel => "100970_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/entrez-gene/11651",
                :inScheme => "http://www.openbel.org/bel/namespace/entrez-gene",
                :identifier => "11651",
                :prefLabel => "11651",
                :title => "thymoma viral proto-oncogene 1"
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1368862_PM_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1368862_PM_at",
                :prefLabel => "1368862_PM_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/entrez-gene/24185",
                :inScheme => "http://www.openbel.org/bel/namespace/entrez-gene",
                :identifier => "24185",
                :prefLabel => "24185",
                :title => "v-akt murine thymoma viral oncogene homolog 1"
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1368862_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1368862_at",
                :prefLabel => "1368862_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1375178_PM_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1375178_PM_at",
                :prefLabel => "1375178_PM_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1375178_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1375178_at",
                :prefLabel => "1375178_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1383126_PM_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1383126_PM_at",
                :prefLabel => "1383126_PM_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1383126_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1383126_at",
                :prefLabel => "1383126_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1416657_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1416657_at",
                :prefLabel => "1416657_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1425711_a_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1425711_a_at",
                :prefLabel => "1425711_a_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1440950_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1440950_at",
                :prefLabel => "1440950_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/affy-probeset/1442759_at",
                :inScheme => "http://www.openbel.org/bel/namespace/affy-probeset",
                :identifier => "1442759_at",
                :prefLabel => "1442759_at",
                :title => ""
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/swissprot/P31750",
                :inScheme => "http://www.openbel.org/bel/namespace/swissprot",
                :identifier => "Q6GSA6",
                :prefLabel => "AKT1_MOUSE",
                :title => "RAC-alpha serine/threonine-protein kinase"
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/mgi-mouse-genes/87986",
                :inScheme => "http://www.openbel.org/bel/namespace/mgi-mouse-genes",
                :identifier => "87986",
                :prefLabel => "Akt1",
                :title => "thymoma viral proto-oncogene 1"
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/swissprot/P47196",
                :inScheme => "http://www.openbel.org/bel/namespace/swissprot",
                :identifier => "P47196",
                :prefLabel => "AKT1_RAT",
                :title => "RAC-alpha serine/threonine-protein kinase"
              },
              {
                :uri => "http://www.openbel.org/bel/namespace/rgd-rat-genes/2081",
                :inScheme => "http://www.openbel.org/bel/namespace/rgd-rat-genes",
                :identifier => "2081",
                :prefLabel => "Akt1",
                :title => "v-akt murine thymoma viral oncogene homolog 1"
              }
            ]
          }
        status 200, "One namespace exists for :namespace"
        status 404, "No namespace exists for :namespace"
      end
      get '/namespaces/:namespace/orthologs/?' do |namespace|
        halt 400 unless request.params['value']

        values = CGI::parse(env["QUERY_STRING"])['value']
        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        orth_mapping = @api.find_orthologs(namespace, values, options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump orth_mapping
      end

      post '/namespaces/:namespace/orthologs/?' do |namespace|
        halt 400 unless request.media_type == 'application/json'

        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        request.body.rewind
        json_body = JSON.parse request.body.read
        halt 400 unless json_body['values']

        eq_mapping = @api.find_orthologs(namespace, json_body['values'], options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump(eq_mapping)
      end

      # WORKS (Most of AFFX missing due to gdbm build)
      get '/namespaces/:namespace/:id/?' do |namespace, value|
        value = @api.find_namespace_value(namespace, value)

        halt 404 unless value

        status 200
        render_single(request, value, 'Namespace Value')
      end

      # BROKEN (Equivalent concept uri not saved; add to eq_array and ol_array
      get '/namespaces/:namespace/:id/equivalents/?' do |namespace, value|
        equivalents = @api.find_equivalent(namespace, value)
        halt 404 if not equivalents or equivalents.empty?

        render_multiple(request, equivalents, "Equivalents for #{namespace} / #{value}")
      end

      get '/namespaces/:namespace/:id/equivalents/:target/?' do |namespace, value, target|
        equivalent = @api.find_equivalent(namespace, value, {
          target: target
        })

        halt 404 unless equivalent

        render_single(request, equivalent, "Equivalent for #{namespace} / #{value} in #{target}")
      end

      get '/namespaces/:namespace/:id/orthologs/?' do |namespace, value|
        orthologs = @api.find_ortholog(namespace, value)
        if not orthologs or orthologs.empty?
          halt 404
        end

        render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value}")
      end

      get '/namespaces/:namespace/:id/orthologs/:target/?' do |namespace, value, target|
        orthologs = @api.find_ortholog(namespace, value, {
          target: target
        })
        if not orthologs or orthologs.empty?
          halt 404
        end

        render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value} in #{target}")
      end

      doc_endpoint "/help/namespaces"
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
