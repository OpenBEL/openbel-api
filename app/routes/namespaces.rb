require 'rack'
require 'sinatra/base'
require 'sinatra/reloader'
require 'docdsl'
require 'cgi'
require 'oj'
require 'uri'

APP_ROOT = OpenBEL::Util::path(File.dirname(__FILE__), '..')

require 'namespace/model'
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
                      - [GET /namespaces/:namespace/equivalents?value=...](#get-namespacesnamespaceequivalents)
                      - [GET /namespaces/:namespace/orthologs?value=...](#get-namespacesnamespaceorthologs)
                      - [GET /namespaces/:namespace/:id](#get-namespacesnamespaceid)
                      - [GET /namespaces/:namespace/:id/equivalents](#get-namespacesnamespaceidequivalents)
                      - [GET /namespaces/:namespace/:id/equivalents/:target](#get-namespacesnamespaceidequivalentstarget)
                      - [GET /namespaces/:namespace/:id/orthologs](#get-namespacesnamespaceidorthologs)
                      - [GET /namespaces/:namespace/:id/orthologs/:target](#get-namespacesnamespaceidorthologstarget)
                      ".squeeze(' ')
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
        status 400, "No :value parameters provided; target :namespace parameter does not exist; the :result parameter does not match one of #{RESULT_TYPES.keys.join(', ')}"
        status 404, "No namespace exists for :namespace; One or more :value do not have equivalents"
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
        halt 404 if eq_mapping.values.all? { |v| v == nil }
        response.headers['Content-Type'] = 'application/json'
        Oj::dump eq_mapping
      end

      post '/namespaces/:namespace/equivalents/?' do |namespace|
        halt 400 unless request.media_type == 'application/x-www-form-urlencoded'

        content = request.body.read
        halt 400 if content.empty?

        params = Hash[
          URI.decode_www_form(content).group_by(&:first).map{
            |k,a| [k,a.map(&:last)]
          }
        ]

        halt 400 unless params['value']

        options = {}
        if params['namespace']
          options[:target] = params['namespace'].first
        end

        if params['result']
          result = params['result'].first.to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        eq_mapping = @api.find_equivalents(namespace, params['value'], options)
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
        status 200, "Mapping performed for :value parameters"
        status 400, "No :value parameters provided; target :namespace parameter does not exist; the :result parameter does not match one of #{RESULT_TYPES.keys.join(', ')}"
        status 404, "No namespace exists for :namespace; One or more :value do not have orthologs"
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
        halt 404 if orth_mapping.values.all? { |v| v == nil }
        response.headers['Content-Type'] = 'application/json'
        Oj::dump orth_mapping
      end

      post '/namespaces/:namespace/orthologs/?' do |namespace|
        halt 400 unless request.media_type == 'application/x-www-form-urlencoded'

        content = request.body.read
        halt 400 if content.empty?

        params = Hash[
          URI.decode_www_form(content).group_by(&:first).map{
            |k,a| [k,a.map(&:last)]
          }
        ]

        halt 400 unless params['value']

        options = {}
        if params['namespace']
          options[:target] = params['namespace'].first
        end

        if params['result']
          result = params['result'].first.to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        orth_mapping = @api.find_orthologs(namespace, params['value'], options)
        response.headers['Content-Type'] = 'application/json'
        Oj::dump(orth_mapping)
      end

      documentation "Retrieve a single namespace value by *name*, *identfier*, or *title*.

                     > example (by identifier): ``curl http://localhost:3000/namespaces/hgnc/391``

                     > [try html](/namespaces/hgnc/391)

                     > example (by name): ``curl http://localhost:3000/namespaces/hgnc/AKT1``

                     > [try html](/namespaces/hgnc/AKT1)

                     > example (by title): ``curl \"http://localhost:3000/namespaces/hgnc/v-akt%20murine%20thymoma%20viral%20oncogene%20homolog%201\"``

                     > [try html](/namespaces/hgnc/v-akt murine thymoma viral oncogene homolog 1)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        param :id, "namespace value by *name*, *identifier*, or *title*"
        response "namespace value **object**",
          {
            :rdf_uri => "http://www.openbel.org/bel/namespace/hgnc-human-genes/391",
            :identifier => "391",
            :name => "AKT1",
            :title => "v-akt murine thymoma viral oncogene homolog 1",
            :links => [
              {
                :rel => "self",
                :href => "http://localhost:3000/namespaces/hgnc-human-genes/391"
              },
              {
                :rel => "parent",
                :href => "http://localhost:3000/namespaces/hgnc-human-genes"
              },
              {
                :rel => "equivalents",
                :href => "http://localhost:3000/namespaces/hgnc-human-genes/391/equivalents"
              },
              {
                :rel => "orthology",
                :href => "http://localhost:3000/namespaces/hgnc-human-genes/391/orthologs"
              }
            ]
          }
        status 200, "The namespace value *:id* exists in *:namespace*"
        status 404, "The :namespace does not exist or *:id* does not exist in :namespace"
      end
      get '/namespaces/:namespace/:id/?' do |namespace, value|
        value = @api.find_namespace_value(namespace, value)

        halt 404 unless value

        status 200
        render_single(request, value, 'Namespace Value')
      end

      documentation "Retrieve the equivalents for a single namespace value by *name*, *identfier*, or *title*.

                     > example (by identifier): ``curl http://localhost:3000/namespaces/hgnc/391/equivalents``

                     > [try html](/namespaces/hgnc/391/equivalents)

                     > example (by name): ``curl http://localhost:3000/namespaces/hgnc/AKT1/equivalents``

                     > [try html](/namespaces/hgnc/AKT1/equivalents)

                     > example (by title): ``curl \"http://localhost:3000/namespaces/hgnc/v-akt%20murine%20thymoma%20viral%20oncogene%20homolog%201/equivalents\"``

                     > [try html](/namespaces/hgnc/v-akt murine thymoma viral oncogene homolog 1/equivalents)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        param :id, "namespace value by *name*, *identifier*, or *title*"
        response "**array** of equivalent namespace value objects",
          [
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1564_at",
              :identifier => "1564_at",
              :name => "1564_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1564_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1564_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1564_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/entrez-gene/207",
              :identifier => "207",
              :name => "207",
              :title => "v-akt murine thymoma viral oncogene homolog 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/entrez-gene/207"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/entrez-gene"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/entrez-gene/207/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/entrez-gene/207/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/207163_PM_s_at",
              :identifier => "207163_PM_s_at",
              :name => "207163_PM_s_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/207163_PM_s_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/207163_PM_s_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/207163_PM_s_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/207163_s_at",
              :identifier => "207163_s_at",
              :name => "207163_s_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/207163_s_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/207163_s_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/207163_s_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/swissprot/P31749",
              :identifier => "Q9BWB6",
              :name => "AKT1_HUMAN",
              :title => "RAC-alpha serine/threonine-protein kinase",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/swissprot/P31749"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/swissprot"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/swissprot/P31749/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/swissprot/P31749/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/hgnc-human-genes/391",
              :identifier => "391",
              :name => "AKT1",
              :title => "v-akt murine thymoma viral oncogene homolog 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/hgnc-human-genes/391"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/hgnc-human-genes"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/hgnc-human-genes/391/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/hgnc-human-genes/391/orthologs"
                }
              ]
            }
          ]
        status 200, "Equivalents exist for the namespace value *:id* in *:namespace*"
        status 404, ":namespace does not exist, *:id* does not exist in :namespace, or no equivalents exist for *:id*"
      end
      get '/namespaces/:namespace/:id/equivalents/?' do |namespace, value|
        equivalents = @api.find_equivalent(namespace, value)
        halt 404 if not equivalents or equivalents.empty?

        render_multiple(request, equivalents, "Equivalents for #{namespace} / #{value}")
      end

      documentation "Retrieve target namespace equivalents for a single namespace value by *name*, *identfier*, or *title*.

                     > example (by identifier): ``curl http://localhost:3000/namespaces/hgnc/391/equivalents/egid``

                     > [try html](/namespaces/hgnc/391/equivalents/egid)

                     > example (by name): ``curl http://localhost:3000/namespaces/hgnc/AKT1/equivalents/Entrez%20Gene``

                     > [try html](/namespaces/hgnc/AKT1/equivalents/Entrez Gene)

                     > example (by title): ``curl \"http://localhost:3000/namespaces/hgnc/v-akt%20murine%20thymoma%20viral%20oncogene%20homolog%201/equivalents/egid\"``

                     > [try html](/namespaces/hgnc/v-akt murine thymoma viral oncogene homolog 1/equivalents/egid)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        param :id, "namespace value by *name*, *identifier*, or *title*"
        param :target, "target namespace prefix (e.g. EGID) or name (e.g. Entrez Gene)"
        response "**array** of target equivalent namespace value objects",
          [
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/entrez-gene",
              :identifier => "207",
              :name => "207",
              :title => "v-akt murine thymoma viral oncogene homolog 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/entrez-gene"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/entrez-gene/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/entrez-gene/orthologs"
                }
              ]
            }
          ]
        status 200, "Target equivalents exist for the namespace value *:id* in *:namespace*"
        status 404, ":namespace does not exist, *:id* does not exist in :namespace, or no :target equivalents exist for *:id*"
      end
      get '/namespaces/:namespace/:id/equivalents/:target/?' do |namespace, value, target|
        equivalent = @api.find_equivalent(namespace, value, {
          target: target
        })

        halt 404 unless equivalent

        render_single(request, equivalent, "Equivalent for #{namespace} / #{value} in #{target}")
      end

      documentation "Retrieve the orthologs for a single namespace value by *name*, *identfier*, or *title*.

                     > example (by identifier): ``curl http://localhost:3000/namespaces/hgnc/391/orthologs``

                     > [try html](/namespaces/hgnc/391/orthologs)

                     > example (by name): ``curl http://localhost:3000/namespaces/hgnc/AKT1/orthologs``

                     > [try html](/namespaces/hgnc/AKT1/orthologs)

                     > example (by title): ``curl \"http://localhost:3000/namespaces/hgnc/v-akt%20murine%20thymoma%20viral%20oncogene%20homolog%201/orthologs\"``

                     > [try html](/namespaces/hgnc/v-akt murine thymoma viral oncogene homolog 1/orthologs)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        param :id, "namespace value by *name*, *identifier*, or *title*"
        response "**array** of ortholog namespace value objects",
          [
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/100970_at",
              :identifier => "100970_at",
              :name => "100970_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/100970_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/100970_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/100970_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/entrez-gene/11651",
              :identifier => "11651",
              :name => "11651",
              :title => "thymoma viral proto-oncogene 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/entrez-gene/11651"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/entrez-gene"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/entrez-gene/11651/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/entrez-gene/11651/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1368862_PM_at",
              :identifier => "1368862_PM_at",
              :name => "1368862_PM_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1368862_PM_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1368862_PM_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1368862_PM_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/entrez-gene/24185",
              :identifier => "24185",
              :name => "24185",
              :title => "v-akt murine thymoma viral oncogene homolog 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/entrez-gene/24185"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/entrez-gene"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/entrez-gene/24185/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/entrez-gene/24185/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1368862_at",
              :identifier => "1368862_at",
              :name => "1368862_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1368862_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1368862_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1368862_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1375178_PM_at",
              :identifier => "1375178_PM_at",
              :name => "1375178_PM_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1375178_PM_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1375178_PM_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1375178_PM_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1375178_at",
              :identifier => "1375178_at",
              :name => "1375178_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1375178_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1375178_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1375178_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1383126_PM_at",
              :identifier => "1383126_PM_at",
              :name => "1383126_PM_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1383126_PM_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1383126_PM_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1383126_PM_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1383126_at",
              :identifier => "1383126_at",
              :name => "1383126_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1383126_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1383126_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1383126_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1416657_at",
              :identifier => "1416657_at",
              :name => "1416657_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1416657_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1416657_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1416657_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1425711_a_at",
              :identifier => "1425711_a_at",
              :name => "1425711_a_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1425711_a_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1425711_a_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1425711_a_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1440950_at",
              :identifier => "1440950_at",
              :name => "1440950_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1440950_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1440950_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1440950_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/affy-probeset/1442759_at",
              :identifier => "1442759_at",
              :name => "1442759_at",
              :title => "",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1442759_at"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/affy-probeset"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1442759_at/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/affy-probeset/1442759_at/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/swissprot/P31750",
              :identifier => "Q6GSA6",
              :name => "AKT1_MOUSE",
              :title => "RAC-alpha serine/threonine-protein kinase",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/swissprot/P31750"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/swissprot"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/swissprot/P31750/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/swissprot/P31750/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/mgi-mouse-genes/87986",
              :identifier => "87986",
              :name => "Akt1",
              :title => "thymoma viral proto-oncogene 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/mgi-mouse-genes/87986"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/mgi-mouse-genes"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/mgi-mouse-genes/87986/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/mgi-mouse-genes/87986/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/swissprot/P47196",
              :identifier => "P47196",
              :name => "AKT1_RAT",
              :title => "RAC-alpha serine/threonine-protein kinase",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/swissprot/P47196"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/swissprot"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/swissprot/P47196/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/swissprot/P47196/orthologs"
                }
              ]
            },
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/rgd-rat-genes/2081",
              :identifier => "2081",
              :name => "Akt1",
              :title => "v-akt murine thymoma viral oncogene homolog 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/rgd-rat-genes/2081"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/rgd-rat-genes"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/rgd-rat-genes/2081/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/rgd-rat-genes/2081/orthologs"
                }
              ]
            }
          ]
        status 200, "Orthologs exist for the namespace value *:id* in *:namespace*"
        status 404, ":namespace does not exist, *:id* does not exist in :namespace, or no orthologs exist for *:id*"
      end
      get '/namespaces/:namespace/:id/orthologs/?' do |namespace, value|
        orthologs = @api.find_ortholog(namespace, value)
        if not orthologs or orthologs.empty?
          halt 404
        end

        render_multiple(request, orthologs, "Orthologs for #{namespace} / #{value}")
      end

      documentation "Retrieve target namespace orthologs for a single namespace value by *name*, *identfier*, or *title*.

                     > example (by identifier): ``curl http://localhost:3000/namespaces/hgnc/391/orthologs/rgd``

                     > [try html](/namespaces/hgnc/391/orthologs/rgd)

                     > example (by name): ``curl http://localhost:3000/namespaces/hgnc/AKT1/orthologs/Rgd%20Rat%20Genes``

                     > [try html](/namespaces/hgnc/AKT1/orthologs/Rgd Rat Genes)

                     > example (by title): ``curl \"http://localhost:3000/namespaces/hgnc/v-akt%20murine%20thymoma%20viral%20oncogene%20homolog%201/orthologs/rgd\"``

                     > [try html](/namespaces/hgnc/v-akt murine thymoma viral oncogene homolog 1/orthologs/rgd)
                     ".squeeze(' ') do
        param :namespace, "namespace prefix (e.g. HGNC) or name (e.g. Hgnc Human Genes)"
        param :id, "namespace value by *name*, *identifier*, or *title*"
        param :target, "target namespace prefix (e.g. EGID) or name (e.g. Entrez Gene)"
        response "**array** of target ortholog namespace value objects",
          [
            {
              :rdf_uri => "http://www.openbel.org/bel/namespace/rgd-rat-genes",
              :identifier => "2081",
              :name => "Akt1",
              :title => "v-akt murine thymoma viral oncogene homolog 1",
              :links => [
                {
                  :rel => "self",
                  :href => "http://localhost:3000/namespaces/rgd-rat-genes"
                },
                {
                  :rel => "parent",
                  :href => "http://localhost:3000/namespaces/"
                },
                {
                  :rel => "equivalents",
                  :href => "http://localhost:3000/namespaces/rgd-rat-genes/equivalents"
                },
                {
                  :rel => "orthology",
                  :href => "http://localhost:3000/namespaces/rgd-rat-genes/orthologs"
                }
              ]
            }
          ]
        status 200, "Target equivalents exist for the namespace value *:id* in *:namespace*"
        status 404, ":namespace does not exist, *:id* does not exist in :namespace, or no :target equivalents exist for *:id*"
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
