# Sunspot Matchers

[Sunspot](http://outoftime.github.com/sunspot/) is a great Ruby library for constructing searches against Solr.  However,
because of the way the Sunspot DSL is constructed, it can be difficult to do simple assertions about your searches
without doing full integration tests.

The goal of these matchers are to make it easier to unit test search logic without having to construct the individual
fixture scenarios inside of Solr and then actually perform a search against Solr.

This is a direct port of the excellent [Sunspot Matchers](http://github.com/pivotal/sunspot_matchers) library by Joseph
Palermo, rewritten for use with Test::Unit.

# Installation

To get started, `gem install sunspot_matchers_testunit` from the command prompt or add it to your Gemfile.

You will need to replace the Sunspot Session object with the spy provided.  You can do this globally by putting the
following in a setup block or your test_helper.

    def setup
      Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
    end

Keep in mind, this will prevent any test from actually hitting Solr, so if you have integration tests, you'll either
need to be more careful which tests you replace the session for, or you'll need to restore the original session before
those tests

    Sunspot.session = Sunspot.session.original_session

You will also need to include the matchers in your tests.  Again, this can be done globally in your test_helper.

    require 'sunspot_matchers_testunit'
    include SunspotMatchersTestunit

Alternately, you could include them into individual tests if needed.

# Matchers

## assert_is_search_for

If you perform a search against your Post model, you could write this assertion:

`assert_is_search_for Sunspot.session, Post`

Individual searches are stored in an array, so if you perform multiple, you'll have to match against them manually.  Without
an explicit search specified, it will use the last one.

`assert_is_search_for Sunspot.session.searches.first, Post`

## assert_has_search_params

This is where the bulk of the functionality lies.  There are seven types of search matches you can perform: `keywords`,
`with`, `without`, `paginate`, `order_by`, `facet`, and `boost`.

In all of the examples below, the arguments fully match the search terms.  This is not expected or required.  You can
have a dozen `with` restrictions on a search and still write an expectation on a single one of them.

Negative expectations also work correctly.  `assert_has_no_search_params` will fail if the search actually includes the
provided arguments.

With all matchers, you can specify a `Proc` as the second argument, and perform multi statement expectations inside the
Proc.  Keep in mind, that only the search type specified in the first argument will actually be checked.  So if you specify
`keywords` and `with` restrictions in the same Proc, but you said `assert_has_search_params Sunspot.session, :keywords, ...`
the `with` restrictions are simply ignored.

### wildcard matching

keywords, with, without, and order_by support wildcard expectations using the `any_param` parameter:

    Sunspot.search(Post) do
      with :blog_id, 4
      order_by :blog_id, :desc
    end

    assert_has_search_params Sunspot.session, :with, :blog_id, any_param
    assert_has_search_params Sunspot.session, :order_by, :blog_id, any_param
    assert_has_search_params Sunspot.session, :order_by, any_param
    assert_has_no_search_params Sunspot.session, :order_by, :category_ids, any_param

### :keywords

You can match against a keyword search:

    Sunspot.search(Post) do
      keywords 'great pizza'
    end

    assert_has_search_params Sunspot.session, :keywords, 'great pizza'

### :with

You can match against a with restriction:

    Sunspot.search(Post) do
      with :author_name, 'Mark Twain'
    end

    assert_has_search_params Sunspot.session, :with, :author_name, 'Mark Twain'

Complex conditions can be matched by using a Proc instead of a value.  Be aware that order does matter, not for
the actual results that would come out of Solr, but the matcher will fail of the order of `with` restrictions is
different.

    Sunspot.search(Post) do
      any_of do
        with :category_ids, 1
        with :category_ids, 2
      end
    end

    assert_has_search_params Sunspot.session, :with, Proc.new {
      any_of do
        with :category_ids, 1
        with :category_ids, 2
      end
    }

### :without

Without is nearly identical to with:

    Sunspot.search(Post) do
      without :author_name, 'Mark Twain'
    end

    assert_has_search_params Sunspot.session, :without, :author_name, 'Mark Twain'

### :paginate

You can also specify only page or per_page, both are not required.

    Sunspot.search(Post) do
      paginate :page => 3, :per_page => 15
    end

    assert_has_search_params Sunspot.session, :paginate, :page => 3, :per_page => 15

### :order_by

Expectations on multiple orderings are supported using using the Proc format mentioned above.

    Sunspot.search(Post) do
      order_by :published_at, :desc
    end

    assert_has_search_params Sunspot.session, :order_by, :published_at, :desc

### :facet

Standard faceting expectation:

    Sunspot.search(Post) do
      facet :category_ids
    end

    assert_has_search_params Sunspot.session, :facet, :category_ids

Faceting where a query is excluded:

    Sunspot.search(Post) do
      category_filter = with(:category_ids, 2)
      facet(:category_ids, :exclude => category_filter)
    end

    assert_has_search_params Sunspot.session, :facet, Proc.new {
      category_filter = with(:category_ids, 2)
      facet(:category_ids, :exclude => category_filter)
    }

Query faceting:

    Sunspot.search(Post) do
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..3.0)
        end
      end
    end
    
    assert_has_search_params Sunspot.session, :facet, Proc.new {
      facet(:average_rating) do
        row(1.0..2.0) do
          with(:average_rating, 1.0..2.0)
        end
        row(2.0..3.0) do
          with(:average_rating, 2.0..3.0)
        end
      end
    }

### :boost

Field boost matching:

    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost_fields :body => 2.0
      end
    end

    assert_has_search_params Sunspot.session, :boost, Proc.new {
      keywords 'great pizza' do
        boost_fields :body => 2.0
      end
    }

Boost query matching:

    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 4
        end
      end
    end

    assert_has_search_params Sunspot.session, :boost, Proc.new {
      keywords 'great pizza' do
        boost(2.0) do
          with :blog_id, 4
        end
      end
    }

Boost function matching:

    Sunspot.search(Post) do
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 10)) })
      end
    end

    assert_has_search_params Sunspot.session, :boost, Proc.new {
      keywords 'great pizza' do
        boost(function { sum(:average_rating, product(:popularity, 10)) })
      end
    }
