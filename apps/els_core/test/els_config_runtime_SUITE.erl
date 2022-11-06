%%==============================================================================
%% Unit Tests for Runtime Config
%%==============================================================================
-module(els_config_runtime_SUITE).

%% CT Callbacks
-export([
    all/0,
    init_per_suite/1,
    end_per_suite/1,
    init_per_testcase/2,
    end_per_testcase/2,
    suite/0
]).

%% Test cases
-export([
    use_long_names_true/1,
    use_long_names_false/1,
    use_long_names_custom_domain/1,
    use_long_names_custom_hostname/1
]).

%%==============================================================================
%% Includes
%%==============================================================================
-include_lib("stdlib/include/assert.hrl").

%%==============================================================================
%% Types
%%==============================================================================
-type config() :: [{atom(), any()}].

%%==============================================================================
%% CT Callbacks
%%==============================================================================
-spec all() -> [atom()].
all() ->
    [
        use_long_names_true,
        use_long_names_false,
        use_long_names_custom_domain,
        use_long_names_custom_hostname
    ].

-spec init_per_suite(config()) -> config().
init_per_suite(Config) ->
    application:start(yamerl),
    Config.

-spec end_per_suite(config()) -> ok.
end_per_suite(_Config) ->
    application:stop(yamerl),
    ok.

-spec init_per_testcase(atom(), config()) -> config().
init_per_testcase(_TestCase, Config) ->
    {ok, _} = els_config:start_link(),
    Config.

-spec end_per_testcase(atom(), config()) -> ok.
end_per_testcase(_TestCase, _Config) ->
    gen_server:stop(els_config),
    ok.

-spec suite() -> [tuple()].
suite() ->
    [{timetrap, {seconds, 30}}].

%%==============================================================================
%% Testcases
%%==============================================================================
-spec use_long_names_true(config()) -> ok.
use_long_names_true(_TestConfig) ->
    ConfigYaml =
        "runtime:\n"
        "  use_long_names: true\n"
        "  cookie: mycookie\n"
        "  node_name: my_node\n",
    init_with_config(ConfigYaml),

    {ok, HostName} = inet:gethostname(),
    NodeName = "my_node@" ++ in_current_domain(HostName),
    Node = list_to_atom(NodeName),

    ?assertEqual(Node, els_config_runtime:get_node_name()),
    ok.

-spec use_long_names_false(config()) -> ok.
use_long_names_false(_TestConfig) ->
    ConfigYaml =
        "runtime:\n"
        "  use_long_names: false\n"
        "  cookie: mycookie\n"
        "  node_name: my_node\n",
    init_with_config(ConfigYaml),

    {ok, HostName} = inet:gethostname(),
    NodeName = "my_node@" ++ HostName,
    Node = list_to_atom(NodeName),

    ?assertEqual(Node, els_config_runtime:get_node_name()),
    ok.

-spec use_long_names_custom_domain(config()) -> ok.
use_long_names_custom_domain(_TestConfig) ->
    ConfigYaml =
        "runtime:\n"
        "  use_long_names: true\n"
        "  cookie: mycookie\n"
        "  node_name: my_node\n"
        "  domain: test.local\n",
    init_with_config(ConfigYaml),

    {ok, HostName} = inet:gethostname(),
    NodeName = "my_node@" ++ HostName ++ ".test.local",
    Node = list_to_atom(NodeName),

    ?assertEqual(Node, els_config_runtime:get_node_name()),
    ok.

-spec use_long_names_custom_hostname(config()) -> ok.
use_long_names_custom_hostname(_TestConfig) ->
    ConfigYaml =
        "runtime:\n"
        "  use_long_names: true\n"
        "  cookie: mycookie\n"
        "  node_name: my_node\n"
        "  hostname: 127.0.0.1\n",
    init_with_config(ConfigYaml),

    HostName = "127.0.0.1",
    NodeName = "my_node@" ++ in_current_domain(HostName),
    Node = list_to_atom(NodeName),

    ?assertEqual(HostName, els_config_runtime:get_hostname()),
    ?assertEqual(Node, els_config_runtime:get_node_name()),
    ok.

%%==============================================================================
%% Internal Functions
%%==============================================================================

-spec init_with_config(string()) -> ok.
init_with_config(ConfigYaml) ->
    RootUri = els_uri:uri(els_utils:to_binary(code:root_dir())),
    [ConfigMap] = yamerl:decode(ConfigYaml, [{map_node_format, map}]),
    els_config:do_initialize(RootUri, #{}, #{}, {undefined, ConfigMap}).

-spec in_current_domain(string()) -> string().
in_current_domain(HostName) ->
    case proplists:lookup(domain, inet:get_rc()) of
        {domain, Domain} -> HostName ++ "." ++ Domain;
        none -> HostName
    end.
