module OpenBEL
  module Search
    module Ranking

      # columns with zero weight:
      #   uri, concept_type, scheme_uri, scheme_type, species
      # columns with non-zero weight:
      #   identifier, pref_label, title, alt_labels, text
      def rank_by_hits(sqlite3_func, sqlite3_matchinfo)
        score = 0.0
        column_index = 0
        weights = [0.0, 0.0, 0.0, 0.0, 0.0, 0.50, 1.0, 0.50, 0.25, 0.10]
        weights_length = weights.length
        values = sqlite3_matchinfo.unpack('L*')
        values[2..-1].each_slice(3) do |hit_cur, hit_all, _|
          if hit_all > 0
            score += ((hit_cur.to_f / hit_all.to_f) * weights[column_index])
          end
          column_index += 1
          break if column_index == weights_length
        end
        sqlite3_func.result = score
      end
    end
  end
end
