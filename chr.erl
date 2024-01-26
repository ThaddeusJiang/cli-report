-module(chr).

-export([main/0]).

%% @spec get_histories() -> [string()]
get_histories() ->
    case file:read_file("/Users/tj/.zsh_history") of
        {ok, Bin} ->
            Str = binary_to_list(Bin),
            Lines = string:tokens(Str, "\n"),
            Lines;
        {error, Reason} ->
            io:format("Error: ~s~n", [Reason]),
            exit(Reason)
    end.

% Total count command histories
total(List) -> io:format("👍Total commands           ~-6B~n~n", [length(List)]).

% 🏆Top 10 commands
pick_command(Line) ->
    case string:tokens(Line, " ") of
        [_ | [Str | _]] ->
            case string:tokens(Str, ";") of
                [_ | [Command | _]] -> Command;
                [] -> ""
            end;
        [] ->
            ""
    end.

%% Line = ": 1706239413:0;cd git/ThaddeusJiang"
pick_directory(Line) ->
    case string:tokens(Line, ";") of
        [_ | [Command | _]] ->
            case string:tokens(Command, " ") of
                [_ | [Directory | _]] -> Directory;
                [_] -> nil;
                [] -> nil
            end;
        [] ->
            nil
    end.

max_value_of_map(Map) ->
    lists:max(maps:values(Map)).

count_print(Val, Total) ->
    trunc(Val / Total * 10).

local_time(Line) ->
    Str = string:substr(Line, 3, 10),
    {Int, _} = string:to_integer(Str),
    calendar:system_time_to_local_time(Int, 1).

pick_date(Line) ->
    {Date, _} = local_time(Line),
    Date.

pick_weekday(Line) ->
    Date = pick_date(Line),
    Day = calendar:day_of_the_week(Date),
    Day.

pick_hour(Line) ->
    {_, Time} = local_time(Line),
    {Hour, _, _} = Time,
    Hour.

counts_map(List) ->
    lists:foldl(
        fun(X, Acc) -> maps:update_with(X, fun(V) -> V + 1 end, 1, Acc) end, #{}, List
    ).

top_commands(List) ->
    Commands = [pick_command(Line) || Line <- List, string:find(Line, "cd") == nomatch],
    CountsMap = counts_map(Commands),
    Sorted = lists:sort(fun({_, V1}, {_, V2}) -> V1 > V2 end, maps:to_list(CountsMap)),
    Top10 = lists:sublist(Sorted, 10),

    print_counts("🏆Top 10 commands", Top10).

% 📂Top 10 directories
top_directories(List) ->
    Directories = [pick_directory(Line) || Line <- List, string:find(Line, "cd ") =/= nomatch],

    CountsMap = counts_map(Directories),
    Sorted = lists:sort(fun({_, V1}, {_, V2}) -> V1 > V2 end, maps:to_list(CountsMap)),
    Top10 = lists:sublist(Sorted, 10),
    print_counts("📂Top 10 directories", Top10).

date_to_string({Year, Month, Day}) ->
    io_lib:format("~4..0B-~2..0B-~2..0B", [Year, Month, Day]).

% 💦The busiest day
top_busiest_day(List) ->
    Dates = [pick_date(Line) || Line <- List],
    CountsMap = counts_map(Dates),
    Sorted = lists:sort(fun({_, V1}, {_, V2}) -> V1 > V2 end, maps:to_list(CountsMap)),
    [{Date, Count}] = lists:sublist(Sorted, 1),

    print_counts("💦The busiest day", [{date_to_string(Date), Count}]).

daynum_to_weekday(DayNum) ->
    case DayNum of
        1 -> 'Monday';
        2 -> 'Tuesday';
        3 -> 'Wednesday';
        4 -> 'Thursday';
        5 -> 'Friday';
        6 -> 'Saturday';
        7 -> 'Sunday';
        _ -> 'Invalid'
    end.

print_progress(Title, N) ->
    io:format(" ~s: ", [Title]),
    lists:foreach(
        fun(_) -> io:format("▓") end,
        lists:seq(1, N)
    ),
    io:format("~n").

print_progresses(Title, List) ->
    io:format("~ts~n~n", [list_to_atom(Title)]),
    lists:foreach(
        fun({K, V}) -> print_progress(K, V) end,
        List
    ),
    io:format("~n").

% 📅Weekly Activity
weekly_activity(List) ->
    Dates = [pick_weekday(Line) || Line <- List],
    CountsMap = counts_map(Dates),
    Activity = lists:map(
        fun({K, V}) -> {daynum_to_weekday(K), count_print(V, max_value_of_map(CountsMap))} end,
        maps:to_list(CountsMap)
    ),
    print_progresses("📅Weekly Activity", Activity).

% 🕙Daily Activity
daily_activity(List) ->
    Dates = [pick_hour(Line) || Line <- List],
    CountsMap = counts_map(Dates),
    Activity = lists:map(
        fun({K, V}) -> {integer_to_list(K), count_print(V, max_value_of_map(CountsMap))} end,
        maps:to_list(CountsMap)
    ),
    print_progresses("🕙Daily Activity", Activity).

print_counts(Title, List) ->
    io:format("~ts~n~n", [list_to_atom(Title)]),
    lists:foreach(
        fun({K, V}) ->
            print_aligned(K, V)
        end,
        List
    ),
    io:format("~n").

main() ->
    Histories = get_histories(),
    top_commands(Histories),
    top_directories(Histories),
    top_busiest_day(Histories),
    weekly_activity(Histories),
    daily_activity(Histories),
    total(Histories),
    completed.

print_aligned(Left, Right) ->
    io:format("~-20s ~6B~n", [Left, Right]).
