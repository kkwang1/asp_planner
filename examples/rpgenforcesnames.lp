%*  This file describes a narrative space about enforcing legal names in RPG
    games, inspired by World of Warcraft (which has done this in the past).

    Alex is a closeted trans woman and wants to play World of Warcraft as her
    ideal self, under a new name. Bob is a transphobic cis man who also wishes
    to play World of Warcraft. Meanwhile, World of Warcraft intends to enforce
    legal names for all of their players, after receiving complaints about
    trolling.
*%

%% Facts

person(alex; bob).
trans(alex).
queer(Person) :- trans(Person).
:- queer(Person), not person(Person). % Sanity check
transphobic(bob).
:- transphobic(Person), not person(Person). % Sanity check

game_company(wow).
company(Company) :- game_company(Company).

account_name(legalname; anonymous).

%% Pool of Possible Actions

%*  create_account(Name, Person, Company)
    A person can create a video game account, either using their legal name or
    a new name

    Preconditions: they don't already have an account (for simplicity)

    Effect: the person now has an account under that name type
    
    Effect: if the game company enforces using legal names, then they will
    intend to ID new users. 
*%
possible(I, action(create_account(Name, Person, Company)), al(Person)) :-
    id(I),
    account_name(Name),
    person(Person), 
    company(Company),
    0 { strong_holds(I, has_account(N, Person, Company)) : account_name(N) } 0.

initiates(I, Action, has_account(Name, Person, Company)) :-
    happens(I, Action, al(Person)),
    Action=action(create_account(Name, Person, Company)).

intends(I, added_id(Company, Person), Company) :-
    happens(I, Action, al(Person)),
    Action=action(create_account(_, Person, Company)),
    strong_holds(I, enforces_legal_names(Company)).

%*  play_with(Person1, Person2, Company)
    Two people can play a video game together

    Preconditions: they both have accounts for the same video game

    Effect: the first person has played with the second person, and vice versa.

    Effect: if one of them was a trans person playing under an anonymous account,
    we assume they have gotten to play as their true gender. 

    Effect: If a trans person played as their true gender, the video game
    company linked their account to their legal name, and they played with a
    transphobic person, they will get harassed.
*%
possible(I, action(play_with(Person1, Person2, Company)), al(Person1)) :-
    id(I),
    person(Person1),
    person(Person2),
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
    trans(TransPerson),
    strong_holds(I, has_account(anonymous, TransPerson, Company)).
initiates(I, Action, played_as_true_gender(TransPerson, Company)) :-
    happens(I, Action, al(Partner)),
    Action=action(play_with(Partner, TransPerson, Company)),
    trans(TransPerson),
    strong_holds(I, has_account(anonymous, TransPerson, Company)).

intends(I, harassed(Partner, TransPerson, Company), Partner) :-
    happens(I, Action, al(TransPerson)),
    Action=action(play_with(TransPerson, Partner, Company)),
    trans(TransPerson),
    strong_holds(I, has_account(anonymous, TransPerson, Company)),
    transphobic(Partner),
    strong_holds(I, added_id(Company, TransPerson)).
intends(I, harassed(Partner, TransPerson, Company), Partner) :-
    happens(I, Action, al(Partner)),
    Action=action(play_with(Partner, TransPerson, Company)),
    trans(TransPerson),
    strong_holds(I, has_account(anonymous, TransPerson, Company)),
    transphobic(Partner),
    strong_holds(I, added_id(Company, TransPerson)).

%*  enforce_legal_names(Company)
    A game company can require users to use their legal name

    Preconditions: none

    Effect: the company enforces legal names from now on, meaning that it will
    intend to ID each new user.

    Effect: the company intends to ID each of its existing users
*%
possible(I, action(enforce_legal_names(Company)), al(Company)) :-
    id(I),
    company(Company).

initiates(I, Action, enforces_legal_names(Company)) :-
    happens(I, Action, al(Company)),
    Action=action(enforce_legal_names(Company)).

intends(I, added_id(Company, Person), Company) :-
    happens(I, Action, al(Company)),
    Action=action(enforce_legal_names(Company)),
    strong_holds(I, has_account(_, Person, Company)).

%*  add_id(Company, Person)
    A game company can connect its users to their legal names

    Preconditions: the user has an account in the game and has not already had
    their personal information added
    
    Effect: the company has added the user's personal information to their
    account
*%
possible(I, action(add_id(Company, Person)), al(Company)) :-
    id(I),
    company(Company),
    strong_holds(I, has_account(_, Person, Company)),
    not strong_holds(I, added_id(Company, Person)).

initiates(I, Action, added_id(Company, Person)) :-
    happens(I, Action, al(Company)),
    Action=action(add_id(Company, Person)).

%*  harass(Harasser, Victim, Company)
    A person can harass another person over an online service

    Preconditions: both people have an account on the service

    Effect: the harasser has harassed the victim
*%
possible(I, action(harass(Harasser, Victim, Company)), al(Harasser)) :-
    id(I),
    strong_holds(I, has_account(_, Harasser, Company)),
    strong_holds(I, has_account(_, Victim, Company)),
    Harasser != Victim.

initiates(I, Action, harassed(Harasser, Victim, Company)) :-
    happens(I, Action, al(Harasser)),
    Action=action(harass(Harasser, Victim, Company)).

%% Query Specification

% Trans people in this example intend to play as their true gender in at least one RPG
1 { intends(start, played_as_true_gender(TransPerson, Company), TransPerson) : game_company(Company) } :-
    trans(TransPerson).

% All people in this example intend to play WoW at least once
1 { intends(start, played_with(Person, Partner, wow), Person) : person(Partner), Partner != Person } :-
    person(Person).

% WoW intends to enforce accounts to use their legal names
intends(start, enforces_legal_names(wow), wow).

% Find a narrative that contains the intention of harassment
:- 0 { intends(I, harassed(Harasser, Victim, Company), Harasser) : person(Harasser), person(Victim), company(Company) } 0.

% Use total order
totalorder.

% Number of vertices in the resulting graph:
#const tmax=15.

% Information to be displayed:
#show happens/3.
#show edge/2.
#show satisfies/2.
#show intends/3.
#show strong_holds/2.
#show strong_notholds/2.