# frozen_string_literal: true

require_relative '../test_helper'

module MediaTypes
  class SchemeTest < Minitest::Test
    class TestMediaType
      include MediaTypes::Dsl

      def self.base_format
        'application/vnd.domain.test.%<type>s.v%<version>s%<view>s+%<suffix>s'
      end

      media_type 'scheme'

      defaults do
        version 2
        suffix :json
      end

      validations do
        # "str" => String
        attribute :str, String

        # "maybe_num" => nil | Numeric
        attribute :maybe_num, AllowNil(Numeric)

        # "maybe_object" => nil | Object
        attribute :maybe_object, ::Object, allow_nil: true

        # "collection" => [{ required: String }]
        collection :collection do
          attribute :required, String
        end

        # "collection_of_strings" => [String, String, String]
        collection :collection_of_strings, String

        # "open_collection" => [{ required: String, ... }]
        collection :open_collection do
          attribute :required, String
          not_strict
        end

        # "maybe_empty_collection" => [{ required: String, ... }] | []
        collection :maybe_empty_collection, allow_empty: true do
          attribute :required, String
        end

        # "collection_with_unknown_keys" => [ { ... => { required: String }} ]
        collection :collection_with_unknown_keys do
          any do
            attribute :required, String
          end
        end

        # "key_with_defined_scheme" => { defined: String }
        attribute :key_with_defined_scheme do
          attribute :defined, String
        end

        version 1 do
          attribute :str, String
        end

        view 'create' do
          version 1 do
            attribute :bar, String
          end

          version 2 do
            attribute :bar, Numeric
          end
        end
      end

      registrations :my_media do
        view 'index', :my_media_urls
        view 'collection', :my_medias
        view 'create', :create_my_media

        versions((1..2).to_a)

        type_alias 'scheme.alias'

        suffix :xml
        suffix :json
      end
    end

    PASSING_DATA = {
      str: 'Haddaway',
      maybe_num: 1993,
      maybe_object: { album: :the_album },

      collection: [
        { required: 'what' },
        { required: 'is' }
      ],

      collection_of_strings: ['love'],

      open_collection: [
        { required: 'baby' },
        { required: 'don\'t', next: 'hurt' }
      ],

      key_with_defined_scheme: {
        defined: 'me'
      },

      maybe_empty_collection: [
        { required: 'don\'t' },
        { required: 'hurt' }
      ],

      collection_with_unknown_keys: [
        "unknown": { required: 'me' },
        "other": { required: 'no more' }
      ]
    }.freeze

    def test_it_validates
      assert TestMediaType.valid?(PASSING_DATA)
      assert TestMediaType.validate!(PASSING_DATA)
    end

    def test_it_is_strict_by_default
      assert_raises Scheme::StrictValidationError do
        TestMediaType.validate!(PASSING_DATA.dup.merge(boom: 'chakalaka'))
      end
    end

    def test_it_is_exhaustive_by_default
      assert_raises Scheme::ExhaustedOutputError do
        TestMediaType.validate!(MediaTypes::Hash.new(PASSING_DATA.dup).slice(:str, :maybe_num))
      end
    end

    def test_it_allows_nil_with_wrapper
      assert TestMediaType.validate!(PASSING_DATA.dup.merge(maybe_num: nil))
    end

    def test_it_allows_nil_with_option
      assert TestMediaType.validate!(PASSING_DATA.dup.merge(maybe_object: nil))
    end

    def test_it_fails_on_empty_collection
      assert_raises Scheme::ValidationError do
        TestMediaType.validate!(PASSING_DATA.dup.merge(collection: []))
      end
    end

    def test_it_fails_on_empty_open_collection
      assert_raises Scheme::ValidationError do
        TestMediaType.validate!(PASSING_DATA.dup.merge(open_collection: []))
      end
    end

    def test_it_allows_empty_collection_with_option
      assert TestMediaType.validate!(PASSING_DATA.dup.merge(maybe_empty_collection: []))
    end

    def test_it_fails_on_empty_non_strict_collection
      assert_raises Scheme::ValidationError do
        TestMediaType.validate!(PASSING_DATA.dup.merge(collection_with_unknown_keys: {}))
      end
    end

    def test_it_fails_on_incorrect_attribute_type
      assert_raises Scheme::ValidationError do
        TestMediaType.validate!(PASSING_DATA.dup.merge(str: 42))
      end
    end

    def test_it_fails_on_single_collection_value
      assert_raises Scheme::ValidationError do
        TestMediaType.validate!(PASSING_DATA.dup.merge(key_with_defined_scheme: [{ defined: 'me' }]))
      end
    end

    def test_it_allows_for_versioned_validation
      assert TestMediaType.validate!(
        MediaTypes::Hash.new(PASSING_DATA.dup).slice(:str),
        TestMediaType.to_constructable.version(1)
      )
    end
  end
end
