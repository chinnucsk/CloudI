%%%-------------------------------------------------------------------
%%% @author Mahesh Paolini-Subramanya <mahesh@dieswaytoofast.com>
%%% @copyright (C) 2013 Mahesh Paolini-Subramanya
%%% @doc Root Supervisor for erlasticsearch
%%% @end
%%%
%%% This source file is subject to the New BSD License. You should have received
%%% a copy of the New BSD license with this software. If not, it can be
%%% retrieved from: http://www.opensource.org/licenses/bsd-license.php
%%%-------------------------------------------------------------------
-module(erlasticsearch_poolboy_sup).
-author('Mahesh Paolini-Subramanya <mahesh@dieswaytoofast.com>').

-behaviour(supervisor).

-include("erlasticsearch.hrl").

%% API
-export([start_link/0]).
-export([start_pool/3]).
-export([stop_pool/1]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

-define(WORKER(Restart, Module, Args), {Module, {Module, start_link, Args}, Restart, 5000, worker, [Module]}).
-define(SUPERVISOR(Restart, Module, Args), {Module, {Module, start_link, Args}, Restart, 5000, supervisor, [Module]}).

-type startlink_err() :: {'already_started', pid()} | 'shutdown' | term().
-type startlink_ret() :: {'ok', pid()} | 'ignore' | {'error', startlink_err()}.

-spec start_link() -> startlink_ret().
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec start_pool(pool_name(), params(), params()) -> supervisor:startchild_ret().
start_pool(PoolName, PoolOptions, ConnectionOptions) when is_binary(PoolName),
                                                          is_list(PoolOptions),
                                                          is_list(ConnectionOptions) ->
    PoolSpec = pool_spec(PoolName, PoolOptions, ConnectionOptions),
    supervisor:start_child(?SERVER, PoolSpec).


-spec stop_pool(pool_name()) -> ok | error().
stop_pool(PoolName) ->
    PoolId = erlasticsearch:registered_pool_name(PoolName),
    supervisor:terminate_child(?SERVER, PoolId),
    supervisor:delete_child(?SERVER, PoolId).


-spec init(Args :: term()) -> {ok, {{RestartStrategy :: supervisor:strategy(), MaxR :: non_neg_integer(), MaxT :: non_neg_integer()},
                                    [ChildSpec :: supervisor:child_spec()]}}.
init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 10,
    MaxSecondsBetweenRestarts = 10,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    PoolName = erlasticsearch:get_env(pool_name, ?DEFAULT_POOL_NAME),
    % We need this to be a one_for_one supervisor, because of the way the 
    % connection_options trickle through to the workers (and hence, our
    % gen-server).  To simplify things, I start a default pool of size 0. This
    % ensures that even if ElasticSearch is not up, the application still starts
    % up.
    % NOTE: You can have the pool actually connect and do something by passing
    % in pool_name / pool_options / connection_options in the environment (or by
    % setting it in your app.config)
    PoolOptions = erlasticsearch:get_env(pool_options, [{size, 0},
                                                        {max_overflow, 0}]),
    ConnectionOptions = erlasticsearch:get_env(connection_options, []),
    PoolSpecs = pool_spec(PoolName, PoolOptions, ConnectionOptions),
    {ok, {SupFlags, [PoolSpecs]}}.


-spec pool_spec(pool_name(), params(), params()) -> supervisor:child_spec().
pool_spec(PoolName, PoolOptions, ConnectionOptions) ->
    PoolId = erlasticsearch:registered_pool_name(PoolName),
    PoolArgs = [{name, {local, PoolId}},
                {worker_module, erlasticsearch_poolboy_worker}] ++ PoolOptions,
    poolboy:child_spec(PoolId, PoolArgs, ConnectionOptions).

