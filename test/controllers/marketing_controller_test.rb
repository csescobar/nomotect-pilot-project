require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  test "anonymous user can view public landing page in English" do
    get marketing_path

    assert_response :success
    assert_select "html[lang='en']"
    assert_select "h1", text: /Build with structure/
    assert_select "a[aria-label='NomoTect Home']"
    assert_select "img[alt='NomoTect']"
  end

  test "anonymous user can view public landing page in Brazilian Portuguese" do
    get marketing_path(locale: "pt-BR")

    assert_response :success
    assert_select "html[lang='pt-BR']"
    assert_select "h1", text: /Construa com estrutura/
    assert_select "a", text: "Explorar a plataforma"
  end

  test "renders crawlable discovery and social metadata" do
    get marketing_path

    assert_response :success
    assert_select "link[rel='canonical'][href='http://www.example.com/marketing']", count: 1
    assert_select "meta[name='robots'][content='index,follow,max-image-preview:large']", count: 1
    assert_select "meta[name='google-site-verification'][content='6UWm4w467BVq1xz_vHgalqyWI6kIasR1itiYNhD6XvQ']", count: 1
    assert_select "meta[property='og:type'][content='website']", count: 1
    assert_select "meta[property='og:title'][content=?]", I18n.t("marketing.meta.title"), count: 1
    assert_select "meta[name='twitter:card'][content='summary_large_image']", count: 1
    assert_select "link[rel='icon'][href='/favicon.svg'][type='image/svg+xml']", count: 1
  end

  test "does not render legacy public branding on landing page" do
    get marketing_path

    assert_response :success
    refute_includes response.body, "Rails Hotwire Platform"
  end
end
