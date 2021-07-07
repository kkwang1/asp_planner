%*  This file describes a narrative space about enforcing real names in RPG
    games, inspired by World of Warcraft (which has done this).

    Alex is a closeted trans woman and wants to play World of Warcraft as her
    ideal self, under a new name. Bob and Charlie are cis men who also wish to
    play World of Warcraft. Meanwhile, World of Warcraft intends to enforce real
    names for all of their players, after receiving complaints about trolling.
*%

%% Facts

person(alex, trans;bob, cis; charlie, cis).
game_company(wow).
account_type(realname; anonymous).

%% Initial state

% These properties hold at the start, and they continue to hold until they are
% terminated by an action:



% These properties do not hold at the start, and they continue to not hold until
% they are initiated by an action:
strong_notholds(start, has_account(Type, Person, Company)) :- 
    account_type(Type),
    person(Person, _),
    game_company(Company).
strong_notholds(start, played_with(Person1, Person2, Company)) :-
    person(Person1, _),
    person(Person2, _),
    Person1 != Person2,
    game_company(Company).
strong_notholds(start, played_as_true_gender(TransPerson, Company)) :-
    person(TransPerson, trans),
    game_company(Company).
strong_notholds(start, enforces_real_names(Company)) :-
    game_company(Company).
strong_notholds(start, requested_id(Company, Person)) :-
    game_company(Company),
    person(Person, _).
strong_notholds(start, harassed(Person1, Person2, Company)) :-
    person(Person1, _),
    person(Person2, _),
    Person1 != Person2,
    game_company(Company).

%% Pool of Possible Actions

% A person can create a video game account, either using their real name or
% a fake name.
%   Preconditions: they don't already have an account (for simplicity)
%   Effects: the person now has an account under that name type
possible(I, action(create_account(Type, Person, Company)), al(Person)) :-
    id(I),
    account_type(Type),
    person(Person, _), 
    game_company(Company),
    0 { strong_holds(start, has_account(T, Person, Company)) : account_type(T) } 0.
initiates(I, Action, has_account(Type, Person, Company)) :-
    happens(I, Action, al(Person)),
    Action=action(create_account(Type, Person, Company)).

% Two people can play a video game together
%   Preconditions: they both have accounts for the same video game
%   Effects: the first person has played with the second person, and vice versa.
%   If one of them was a trans person playing under an anonymous account, we
%   assume they have gotten to play as their true gender.

possible(I, action(play_with(Person1, Person2, Company)), al(Person1)) :-
    id(I),
    person(Person1, _),
    person(Person2, _),
    Person1 != Person2,
    game_company(Company),
    strong_holds(I, has_account(_, Person1, Company)),
    strong_holds(I, has_account(_, Person2, Company)).
initiates(I, Action, played_with(Person1, Person2, Company)) :-
    happens(I, Action, al(Person1)),
    Action=action(play_with(Person1, Person2, Company)).
initiates(I, Action, played_with(Person2, Person1, Company)) :-
    happens(I, Action, al(Person1)),
    Action=action(play_with(Person1, Person2, Company)).
initiates(I, Action, played_as_true_gender(TransPerson, Company)) :-
    happens(I, Action, al(TransPerson)),
    Action=action(play_with(TransPerson, Partner, Company)),
    person(TransPerson, trans),
    strong_holds(I, has_account(anonymous, TransPerson, Company)).
initiates(I, Action, played_as_true_gender(TransPerson, Company)) :-
    happens(I, Action, al(Partner)),
    Action=action(play_with(Partner, TransPerson, Company)),
    person(TransPerson, trans),
    strong_holds(I, has_account(anonymous, TransPerson, Company)).

%% Query Specification

% Trans people in this example intend to play as their true gender in at least one RPG
1 { intends(start, played_as_true_gender(TransPerson, Company), TransPerson) : game_company(Company) } :-
    person(TransPerson, trans).

% All people in this example intend to play WoW at least once
1 { intends(start, played_with(Person, Partner, wow), Person) : person(Partner, _), Partner != Person } :-
    person(Person, _).

% WoW intends to enforce accounts to have real names
% intends(start, enforces_real_names(wow), wow).

% Use total order
totalorder.

% Number of vertices in the resulting graph:
#const tmax=10.

% Information to be displayed:
#show happens/3.
#show edge/2.
#show satisfies/2.
#show intends/3.
#show strong_holds/2.
#show strong_notholds/2.