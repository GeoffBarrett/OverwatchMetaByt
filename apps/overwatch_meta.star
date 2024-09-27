"""
Applet: Overwatch Meta
Summary: Overatch 2 Meta Statistics
Description: This app polls the Overwatch 2 Meta information from Overbuff.
Author: GeoffBarrett
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("re.star", "re")
load("bsoup.star", "bsoup")
load("html.star", "html")

FONT = "Dina_r400-6"
LIGHT_BLUE = "#699dff"
WHITE = "#FFFFFF"

CACHE_TIMEOUT_DEFAULT = 120
DAY_IN_SECONDS = 86400
BASE_URL = "https://www.overbuff.com"
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
PCT_PATTERN = "(\\d+\\.\\d+)$"
ALPHA_ALPHA_NUM_PATTERN = "([a-zA-Z]+\\d+\\.\\d+)"
CHAR_TYPE_PATTERN = "(Support|Damage|Tank)$"

PICK_RATE_START = "Pick Rate"
PICK_RATE_STOP = "Highest Win Rate"

HIGHEST_WIN_RATE_START = "Win Rate"
HIGHEST_WIN_RATE_STOP = "Highest KDA Ratio"

# platform types
platform_types = struct(console = "console", pc = "pc")

# game modes
game_modes = struct(quickplay = "quickplay", competitive = "competitive")

# time modes
time_windows = struct(
    all_time = "all_time",
    this_month = "month",
    last_three_months = "3months",
    last_six_months = "6months",
    last_year = "year",
)

# skill tiers
skill_tiers = struct(
    all = "all",
    bronze = "bronze",
    silver = "silver",
    gold = "gold",
    platinum = "platinum",
    diamond = "diamond",
    master = "master",
    grandmaster = "grandmaster",
)

SHORT_HERO_NAME_MAP = {
    "Wrecking Ball": "Ball",
    "Widowmaker": "Widow",
    "Reinhard": "Rein",
    "Soldier: 76": "Soldier",
    "Zenyatta": "Zen",
    "Baptiste": "Bap",
    "Doomfist": "Doom",
    "Lifeweaver": "LW",
    "Brigitte": "Brig",
    "Junker Queen": "J Queen",
    "Ramattra": "Ram",
    "Torbjörn": "Torb",
    "Symmetra": "Sym",
}

def get_shortend_hero_name(hero_name):
    """Retreives the shortened hero name to minimize pixel space.

    Args:
        hero_name (str): the hero name to shorten.

    Returns:
        str: the shortend hero name
    """
    if hero_name in SHORT_HERO_NAME_MAP:
        return SHORT_HERO_NAME_MAP[hero_name]
    return hero_name

def get_cachable_data(url, timeout, params = {}, headers = {}):
    """Retreive HTML data response.

    Args:
        url (str): URL to make a get request to.
        timeout (int): the timeout duration.
        params (Dict[str, str]): parameters.
        headers (Dict[str, str]): headers.

    Returns:
        Response: the HTML response.
    """
    res = http.get(url = url, ttl_seconds = timeout, params = params, headers = headers)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res

def get_split_string_cleaned(input_text, split_pattern):
    """A helper function that splits a string and filters empty strings.

    Args:
        input_text (str): the input text to split.
        split_pattern (str): the pattern to use when splitting.

    Returns:
        List[str]: the list of split text values.
    """
    text_list = []
    for text_value in re.split(split_pattern, input_text):
        if len(text_value) > 0:
            text_list.append(text_value)
    return text_list

def split_by_percentage(input_text):
    """Splits the input text by the "%" sign.

    Args:
        input_text (str): the text to split.

    Returns:
        List[str]: the split text.
    """
    return get_split_string_cleaned(input_text, "%")

def split_by_number(input_text):
    """Splits the input text by the "%" sign.

    Args:
        input_text (str): the text to split.

    Returns:
        List[str]: the split text.
    """
    return get_split_string_cleaned(input_text, ALPHA_ALPHA_NUM_PATTERN)

def get_pick_rate_raw_list(input_text):
    """Retrieves a list of un-processed strings containing the pick-rates.

    The strings are in the following format: "{Character}{CharacterType}{PickPercentage}"

    i.e. "AnaSupport5.00"

    Args:
        input_text (str): the input text to extract the pick rates from.

    Returns:
        List[str]: the extracted pick-rates.
    """

    start_idx = input_text.rfind(PICK_RATE_START)
    if start_idx == -1:
        return []

    stop_idx = input_text.find(PICK_RATE_STOP)
    if stop_idx == -1:
        return []

    pick_rates = input_text[start_idx + len(PICK_RATE_START):stop_idx]

    return split_by_percentage(pick_rates)

def get_win_rate_raw_list(input_text):
    """Retrieves a list of un-processed strings containing the win-rates.

    The win-rates are in the following format: "{Character}{CharacterType}{WinRate}"

    i.e. "AnaSupport5.00"

    Args:
        input_text (str): the input text to extract the win rates from.

    Returns:
        List[str]: the extracted win-rates.
    """

    start_idx = input_text.rfind(HIGHEST_WIN_RATE_START)
    if start_idx == -1:
        return []

    stop_idx = input_text.find(HIGHEST_WIN_RATE_STOP)
    if stop_idx == -1:
        return []

    win_rates = input_text[start_idx + len(HIGHEST_WIN_RATE_START):stop_idx]

    return split_by_percentage(win_rates)

def parse_char_type_percentage(pick_rate_text):
    """Extract the Character - Character Type - Percentage value from text.

    This text contains the statistics in the following format:
    "{Character}{CharacterType}{PickPercentage}".

    Args:
        pick_rate_text (str): HTML text from Overbuff containing the pick rate contents.

    Returns:
        Optional[Tuple[str, str, str]]: an optional
            (character, character_type, pick_rate_percentage) tuple containing the pick rate
            details.
    """

    # extract pick rate percentage
    pick_rate_percentage = re.findall(PCT_PATTERN, pick_rate_text)
    if len(pick_rate_percentage) == 0:
        return None

    pick_rate_percentage = pick_rate_percentage[0]

    # extract character type
    pick_rate_text = re.split(pick_rate_percentage, pick_rate_text)[0]
    character_type = re.findall(CHAR_TYPE_PATTERN, pick_rate_text)
    if len(character_type) == 0:
        return None

    character_type = character_type[0]

    # extract the character's name
    character = re.split(character_type, pick_rate_text)[0]
    return (character, character_type, pick_rate_percentage)

def make_overbuff_get_request(
        parameters = {},
        endpoint = "meta",
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieve a BeautifulSoup object instance ingesting the response from overbuff.com.

    Args:
        parameters (Optional[Dict[str, str]]): the request parameters. Defaults to None.
        endpoint (str, optional): the overbuff endpoint. Defaults to "meta".
        timeout (int): the timeout to cache the response.

    Returns:
        str: request body text.
    """

    # Will receive a 429 without a user-agent specified
    headers = {"User-Agent": USER_AGENT}
    url = "{}/{}".format(BASE_URL, endpoint)
    print("Making request to {} with params {}.".format(url, parameters))
    response = get_cachable_data(url, timeout, params = parameters, headers = headers)

    return response.body()

def get_overbuff_soup_object(
        parameters = {},
        endpoint = "meta",
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieve a BeautifulSoup object instance ingesting the response from overbuff.com.

    Args:
        parameters (Optional[Dict[str, str]]): the request parameters. Defaults to None.
        endpoint (str, optional): the overbuff endpoint. Defaults to "meta".
        timeout (int): the timeout to cache the response.

    Returns:
        SoupNode: the SoupNode instance.
    """

    response = make_overbuff_get_request(
        parameters = parameters,
        endpoint = endpoint,
        timeout = timeout,
    )
    soup = bsoup.parseHtml(response)
    return soup

def get_overbuff_text(
        platform = platform_types.pc,
        game_mode = None,
        time_window = None,
        skill_tier = None,
        endpoint = "meta",
        timeout = CACHE_TIMEOUT_DEFAULT):
    """Retrieves the text contents from Overbuff's end-point.

    Args:
        platform (str, optional): the platform to extract the data for. Defaults to "pc".
        game_mode (str, optional): the game-mode to extract the data for. Defaults to None.
        time_window (str, optional): the time-window to filter the data by. Defaults to None.
        skill_tier (str, optional): the skill tier to filter the data by. Defaults to None.
        endpoint (str, optional): the overbuff endpoint to retrieve text from. Defaults to "meta".
        timeout (int): the timeout to cache the response.

    Returns:
        str: the text content in the "https://www.overbuff.com/{endpoint}" page.
    """

    # initialize the query parameters (platform is not optional)
    params = {"platform": platform}

    # add the game mode if there is one
    if game_mode:
        params["gameMode"] = game_mode

    # add a time window if there is one (and it isn't all time)
    if time_window != None and time_window != time_windows.all_time:
        params["timeWindow"] = time_window

    # add a skill tier if there is one (and it isn't all)
    if skill_tier != None and skill_tier != skill_tiers.all:
        params["skillTier"] = skill_tier

    response = make_overbuff_get_request(
        parameters = params,
        endpoint = endpoint,
        timeout = timeout,
    )

    return html(response).text()

def get_heroes():
    """Retrieve a list of heroes.

    Returns:
        List[str]: The Overwatch heroes.
    """
    heroes = []
    soup = get_overbuff_soup_object(
        parameters = {},
        endpoint = "heroes",
        timeout = DAY_IN_SECONDS,
    )
    for link in soup.find_all("a"):
        if "/heroes/" in str(link):
            hero = link.get_text()
            if not hero:
                continue
            heroes.append(hero)

    print("Heroes received - {}".format(heroes))
    return heroes

def find_image_with_size(image_sources, max_width = 50):
    """Retrieves the image source that does not exceed the `max_width` value.

    Args:
        image_sources (str): a string containing comma separated image sources.
        max_width (float, optional): the maximum width (in pixels). Defaults to 50.

    Returns:
        Optional[str]: the image source.
    """
    image_source = None
    image_width = 0

    images = get_split_string_cleaned(image_sources, ",")
    for image in images:
        image_components = get_split_string_cleaned(image, " ")
        if len(image_components) != 2:
            continue
        (image_src, image_size) = image_components
        width = float(get_split_string_cleaned(image_size, "w")[0])
        if width <= max_width:
            if width > image_width:
                image_width = width
                image_source = image_src
    return image_source

def get_hero_image_map(
        heroes = None,
        max_width = 200):
    """Retrieve a dictionary mapping the hero names to their respective images.

    Args:
        heroes (Optional[List[str]], optional): an optional list of hero names. Defaults to None.
            If None, the list of hero names will be retrieved.
        max_width (int, optional): the maximum image width. Defaults to 50.

    Returns:
        Dict[str, str]: a map of hero name to image.
    """

    hero_image_map = {}

    if heroes == None:
        # retrieve the list of heroes
        heroes = get_heroes()

    soup = get_overbuff_soup_object(
        parameters = {},
        endpoint = "heroes",
    )

    for image in soup.find_all("img"):
        image_attrs = image.attrs()
        hero_name = image_attrs.get("alt")

        if not hero_name:
            continue

        if hero_name not in heroes:
            continue

        hero_image = find_image_with_size(image_attrs.get("srcset"), max_width = max_width)
        hero_image_map[hero_name] = "{}{}".format(BASE_URL, hero_image)

    print("Hero image map: {}".format(hero_image_map))

    return hero_image_map

def render_error(error_message, width = 64):
    return render.Root(child = render.WrappedText(error_message, width = width))

def render_pick_rates(
        platform = platform_types.pc,
        game_mode = game_modes.quickplay,
        time_window = time_windows.last_three_months,
        skill_tier = skill_tiers.all):
    """Renders the pick rates.

    Args:
        platform (str, optional): an optional platform to query pick rates from. Defaults to "pc".
        game_mode (str, optional): an optional game mode to query pick rates from. Defaults to "pc".
        time_window (str, optional): an optional time window to query pick rates from. Defaults to "pc".
        skill_tier (str, optional): an optional skill tier to query pick rates from. Defaults to "pc".

    Returns:
        Root: a root render instance.
    """

    # retreive the HTML text
    meta_text = get_overbuff_text(
        platform = platform,
        game_mode = game_mode,
        time_window = time_window,
        skill_tier = skill_tier,
        endpoint = "meta",
    )

    # retrieve a map of hero name to hero icon
    hero_image_map = get_hero_image_map()

    # list of pick rates (hero_name, hero_class, pick_rate)
    pick_rates_list = get_pick_rate_raw_list(meta_text)

    if len(pick_rates_list) == 0:
        return render_error("Unable to retrieve the pick rate limit.")

    columns = []

    # add title text
    title_row = render.Row(
        children = [render.Text(content = "Pick Rate:", color = LIGHT_BLUE, font = FONT)],
    )

    # add child contents (Hero Image - Hero Name - Pick Rate %)
    for stat in pick_rates_list:
        if len(stat) == 3:
            continue

        pick_rate_details = parse_char_type_percentage(stat)
        if pick_rate_details == None or len(pick_rate_details) != 3:
            continue

        (hero_name, _, pick_rate_percentage) = pick_rate_details
        if hero_name not in hero_image_map:
            print("Unable to find {} in hero map.".format(hero_name))
            continue

        image_url = hero_image_map[hero_name]
        image_rep = http.get(image_url, ttl_seconds = DAY_IN_SECONDS)

        if image_rep.status_code != 200:
            print("Unable to find the image {}.".format(image_url))
            continue

        hero_text = render.Column(
            children = [
                render.Text(content = get_shortend_hero_name(hero_name), color = WHITE, font = FONT),
                render.Text(content = "{}%".format(pick_rate_percentage), color = WHITE, font = FONT),
            ],
        )

        hero_row = render.Row(
            children = [
                render.Image(src = image_rep.body(), width = 18, height = 18),
                hero_text,
            ],
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
        )

        hero_row_with_title = render.Column(
            children = [
                title_row,
                hero_row,
            ],
        )

        columns.append(hero_row_with_title)

    seq = render.Sequence(children = columns)

    return render.Root(
        child = seq,
        delay = 2000,  # ms between frames
        show_full_animation = True,
    )

def main(config):
    return render_pick_rates()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "who",
                name = "Who?",
                desc = "Who to say hello to.",
                icon = "user",
            ),
        ],
    )
