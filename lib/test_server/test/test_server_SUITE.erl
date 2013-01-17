%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2010-2012. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%
%%%-------------------------------------------------------------------
%%% @author Lukas Larsson <lukas@erlang-solutions.com>
%%% @copyright (C) 2011, Erlang Solutions Ltd.
%%% @doc
%%%
%%% @end
%%% Created : 15 Feb 2011 by Lukas Larsson <lukas@erlang-solutions.com>
%%%-------------------------------------------------------------------
-module(test_server_SUITE).

%% Note: This directive should only be used in test suites.
-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include("test_server_test_lib.hrl").

%%--------------------------------------------------------------------
%% COMMON TEST CALLBACK FUNCTIONS
%%--------------------------------------------------------------------

%% @spec suite() -> Info
suite() ->
    [{ct_hooks,[ts_install_cth,test_server_test_lib]}].


%% @spec init_per_suite(Config0) ->
%%               Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
init_per_suite(Config) ->
    [{path_dirs,[proplists:get_value(data_dir,Config)]} | Config].

%% @spec end_per_suite(Config) -> _
end_per_suite(_Config) ->
    io:format("TEST_SERVER_FRAMEWORK: ~p",[os:getenv("TEST_SERVER_FRAMEWORK")]),
    ok.

%% @spec init_per_group(GroupName, Config0) ->
%%               Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
init_per_group(_GroupName, Config) ->
    Config.

%% @spec end_per_group(GroupName, Config0) ->
%%               void() | {save_config,Config1}
end_per_group(_GroupName, _Config) ->
    ok.

%% @spec init_per_testcase(TestCase, Config0) ->
%%               Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
init_per_testcase(_TestCase, Config) ->
    Config.

%% @spec end_per_testcase(TestCase, Config0) ->
%%               void() | {save_config,Config1} | {fail,Reason}
end_per_testcase(_TestCase, _Config) ->
    ok.

%% @spec: groups() -> [Group]
groups() ->
    [].

%% @spec all() -> GroupsAndTestCases | {skip,Reason}
all() ->
    [test_server_SUITE, test_server_parallel01_SUITE,
     test_server_conf02_SUITE, test_server_conf01_SUITE,
     test_server_skip_SUITE, test_server_shuffle01_SUITE,
     test_server_break_SUITE, test_server_cover_SUITE].


%%--------------------------------------------------------------------
%% TEST CASES
%%--------------------------------------------------------------------
%% @spec TestCase(Config0) ->
%%           ok | exit() | {skip,Reason} | {comment,Comment} |
%%           {save_config,Config1} | {skip_and_save,Reason,Config1}
test_server_SUITE(Config) ->
%    rpc:call(Node,dbg, tracer,[]),
%    rpc:call(Node,dbg, p,[all,c]),
%    rpc:call(Node,dbg, tpl,[test_server_ctrl,x]),
    run_test_server_tests("test_server_SUITE",
			  [{test_server_SUITE,skip_case7,"SKIPPED!"}],
			  38, 1, 30, 19, 9, 1, 11, 2, 25, Config).

test_server_parallel01_SUITE(Config) ->
    run_test_server_tests("test_server_parallel01_SUITE", [],
			  37, 0, 19, 19, 0, 0, 0, 0, 37, Config).

test_server_shuffle01_SUITE(Config) ->
    run_test_server_tests("test_server_shuffle01_SUITE", [],
			  130, 0, 0, 76, 0, 0, 0, 0, 130, Config).

test_server_skip_SUITE(Config) ->
    run_test_server_tests("test_server_skip_SUITE", [],
			  3, 0, 1, 0, 0, 1, 3, 0, 0, Config).

test_server_conf01_SUITE(Config) ->
    run_test_server_tests("test_server_conf01_SUITE", [],
			  24, 0, 12, 12, 0, 0, 0, 0, 24, Config).

test_server_conf02_SUITE(Config) ->
    run_test_server_tests("test_server_conf02_SUITE", [],
			  26, 0, 12, 12, 0, 0, 0, 0, 26, Config).

test_server_break_SUITE(Config) ->
    run_test_server_tests("test_server_break_SUITE", [],
			  8, 2, 6, 4, 0, 0, 0, 2, 6, Config).

test_server_cover_SUITE(Config) ->
    case test_server:is_cover() of
	true ->
	    {skip, "Cover already running"};
	false ->
	    PrivDir = ?config(priv_dir,Config),

	    %% Test suite has two test cases
	    %%   tc1 calls cover_helper:foo/0
	    %%   tc2 calls cover_helper:bar/0
	    %% Each function in cover_helper is one line.
	    %%
	    %% First test run skips tc2, so only cover_helper:foo/0 is executed.
	    %% Cover file specifies to include cover_helper in this test run.
	    CoverFile1 = filename:join(PrivDir,"t1.cover"),
	    CoverSpec1 = {include,[cover_helper]},
	    file:write_file(CoverFile1,io_lib:format("~p.~n",[CoverSpec1])),
	    run_test_server_tests("test_server_cover_SUITE",
				  [{test_server_cover_SUITE,tc2,"SKIPPED!"}],
				  4, 0, 2, 1, 1, 0, 1, 0, 3,
				  CoverFile1, Config),

	    %% Next test run skips tc1, so only cover_helper:bar/0 is executed.
	    %% Cover file specifies cross compilation of cover_helper
	    CoverFile2 = filename:join(PrivDir,"t2.cover"),
	    CoverSpec2 = {cross,[{t1,[cover_helper]}]},
	    file:write_file(CoverFile2,io_lib:format("~p.~n",[CoverSpec2])),
	    run_test_server_tests("test_server_cover_SUITE",
				  [{test_server_cover_SUITE,tc1,"SKIPPED!"}],
				  4, 0, 2, 1, 1, 0, 1, 0, 3, CoverFile2, Config),

	    %% Cross cover analyse
	    WorkDir = ?config(work_dir,Config),
	    WC = filename:join([WorkDir,"test_server_cover_SUITE.logs","run.*"]),
	    [D2,D1|_] = lists:reverse(lists:sort(filelib:wildcard(WC))),
	    TagDirs = [{t1,D1},{t2,D2}],
	    test_server_ctrl:cross_cover_analyse(details,TagDirs),

	    %% Check that cover log shows only what is really included
	    %% in the test and cross cover log show the accumulated
	    %% result.
	    {ok,Cover1} = file:read_file(filename:join(D1,"cover.log")),
	    [{cover_helper,{1,1,_}}] = binary_to_term(Cover1),
	    {ok,Cover2} = file:read_file(filename:join(D2,"cover.log")),
	    [] = binary_to_term(Cover2),
	    {ok,Cross} = file:read_file(filename:join(D1,"cross_cover.log")),
	    [{cover_helper,{2,0,_}}] = binary_to_term(Cross),
	    ok
    end.


run_test_server_tests(SuiteName, Skip, NCases, NFail, NExpected, NSucc,
		      NUsrSkip, NAutoSkip, 
		      NActualSkip, NActualFail, NActualSucc, Config) ->
    run_test_server_tests(SuiteName, Skip, NCases, NFail, NExpected, NSucc,
			  NUsrSkip, NAutoSkip,
			  NActualSkip, NActualFail, NActualSucc, false, Config).

run_test_server_tests(SuiteName, Skip, NCases, NFail, NExpected, NSucc,
		      NUsrSkip, NAutoSkip,
		      NActualSkip, NActualFail, NActualSucc, Cover, Config) ->

    WorkDir = proplists:get_value(work_dir, Config),
    ct:log("<a href=\"file://~s\">Test case log files</a>\n",
	   [filename:join(WorkDir, SuiteName++".logs")]),

    Node = proplists:get_value(node, Config),
    {ok,_Pid} = rpc:call(Node,test_server_ctrl, start, []),
    case Cover of
	false ->
	    ok;
	_ ->
	    rpc:call(Node,test_server_ctrl,cover,[Cover,details])
    end,
    rpc:call(Node,
	     test_server_ctrl,add_dir_with_skip,
	     [SuiteName, 
	      [proplists:get_value(data_dir,Config)],SuiteName,
	      Skip]),

    until(fun() ->
		  rpc:call(Node,test_server_ctrl,jobs,[]) =:= []
	  end),
    
    rpc:call(Node,test_server_ctrl, stop, []),

    {ok,Data} =	test_server_test_lib:parse_suite(
		  lists:last(
		    lists:sort(
		      filelib:wildcard(
			filename:join([WorkDir,SuiteName++".logs",
				       "run*","suite.log"]))))),
    check([{"Number of cases",NCases,Data#suite.n_cases},
	   {"Number failed",NFail,Data#suite.n_cases_failed},
	   {"Number expected",NExpected,Data#suite.n_cases_expected},
	   {"Number successful",NSucc,Data#suite.n_cases_succ},
	   {"Number user skipped",NUsrSkip,Data#suite.n_cases_user_skip},
	   {"Number auto skipped",NAutoSkip,Data#suite.n_cases_auto_skip}], ok),
    {NActualSkip,NActualFail,NActualSucc} = 
	lists:foldl(fun(#tc{ result = skip },{S,F,Su}) ->
			     {S+1,F,Su};
			 (#tc{ result = ok },{S,F,Su}) ->
			     {S,F,Su+1};
			(#tc{ result = failed },{S,F,Su}) ->
			     {S,F+1,Su}
			  end,{0,0,0},Data#suite.cases),
    Data.

check([{Str,Same,Same}|T], Status) ->
    io:format("~s: ~p\n", [Str,Same]),
    check(T, Status);
check([{Str,Expected,Actual}|T], _) ->
    io:format("~s: expected ~p, actual ~p\n", [Str,Expected,Actual]),
    check(T, error);
check([], ok) -> ok;
check([], error) -> ?t:fail().

until(Fun) ->
    case Fun() of
	true ->
	    ok;
	false ->
	    timer:sleep(100),
	    until(Fun)
    end.
	  
