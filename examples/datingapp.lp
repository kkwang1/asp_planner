%*  This file describes a narrative space about getting outed to queerphobic
    family as gay and/or polyamorous while using a dating app. Inspired by Ch 4
    of Queer Policy.

    Alice and Bob are both bisexual and they are dating. They would like to
    look for a third person for their relationship, so they both intend to
    sign up for a dating app to look for people. However, they are going to
    travel from the UK to visit Bob's family in the US, and Bob's cousin Carol
    is on the same dating app. 

    The dating app, Tinder, shows you potential matches based on your location
    and it tells you whether you have mutual facebook friends.
*%

%% Facts

person(alice; bob; carol).
bisexual(alice; bob).
queer(Person) :- bisexual(Person).
queerphobic(carol).

family(bob, carol).

gov(us, uk).
location(raleigh, us; london, uk).

dating_app_company(tinder).
company(Company) :- dating_app_company(Company).

account_name(legalname; anonymous).

%% Initial State

% These properties do not hold at the start, and they continue to not hold until
% they are initiated by an action:
strong_holds(start, dating(alice, bob)).
strong_holds(start, at_location(alice, location(london, uk))).
strong_holds(start, at_location(bob, location(london, uk))).
strong_holds(start, at_location(carol, location(raleigh, us))).

%% World Constraints

% Make sure no one is at two places at once
:- strong_holds(I, at_location(Person, Location1)),
   strong_holds(I, at_location(Person, Location2)),
   id(I),
   person(Person),
   Location1 != Location2.

% Order doesn't matter when dating someone, knowing two people are dating, or
% being family
strong_holds(I, dating(Person1, Person2)) :-
    strong_holds(I, dating(Person2, Person1)).
strong_holds(I, knows_dating(Person1, Person2, Person3)) :-
    strong_holds(I, knows_dating(Person1, Person3, Person2)).
family(Person1, Person2) :- family(Person2, Person1).

% Two people inherently know each other if they are dating or if they are family
strong_holds(start, knows(Person1, Person2)) :- family(Person1, Person2).
strong_holds(I, knows(Person1, Person2)) :-
    strong_holds(I, dating(Person1, Person2)).

% You cannot know yourself
:- strong_holds(I, knows(Person, Person)), id(I), person(Person).

%% Pool of Possible Actions

%*  move_to(Person, Location)
    A person can move to a new location

    Preconditions: The person is not already in the new location

    Effect: The person is now in the new location

    Effect: The person is no longer in the location they were in before
*%
possible(I, action(move_to(Person, location(Location, Gov))), al(Person)) :-
    id(I),
    person(Person),
    location(Location, Gov),
    not strong_holds(I, at_location(Person, location(Location, Gov))).

initiates(I, Action, at_location(Person, location(Location, Gov))) :-
    happens(I, Action, al(Person)),
    Action=action(move_to(Person, location(Location, Gov))).

terminates(I, Action, at_location(Person, location(OldLocation, OldGov))) :-
    happens(I, Action, al(Person)),
    Action=action(move_to(Person, location(Location, Gov))),
    strong_holds(I, at_location(Person, location(OldLocation, OldGov))).

%*  introduce_date(Person1, Date, Person2)
    Someone can introduce someone they're dating to another person that they
    know

    Preconditions: Person1 is dating the person they're introducing, Person1
    and Person2 know each other, and all three people are currently at the same
    location

    Effect: Person2 and Person1's date now know each other

    Effect: Person2 now knows Person1 and their date are dating
*%
possible(I, action(introduce_date(Person1, Date, Person2)), al(Person1)) :-
    id(I),
    person(Person1),
    person(Date),
    person(Person2),
    Person1 != Person2,
    Date != Person2,
    strong_holds(I, dating(Person1, Date)),
    strong_holds(I, knows(Person1, Person2)),
    strong_holds(I, knows(Person2, Person1)),
    strong_holds(I, at_location(Person1, Location)),
    strong_holds(I, at_location(Date, Location)),
    strong_holds(I, at_location(Person2, Location)).

initiates(I, Action, knows(Date, Person2)) :-
    happens(I, Action, al(Person1)),
    Action=action(introduce_date(Person1, Date, Person2)).
initiates(I, Action, knows(Person2, Date)) :-
    happens(I, Action, al(Person1)),
    Action=action(introduce_date(Person1, Date, Person2)).

initiates(I, Action, knows_dating(Person2, Person1, Date)) :-
    happens(I, Action, al(Person1)),
    Action=action(introduce_date(Person1, Date, Person2)).

%*  create_account(Name, Person, Company)
    A person can create a dating app account, either using their legal name or
    a new name

    Preconditions: They don't already have an account (for simplicity)

    Effect: The person now has an account under that name type

    Effect: If the person used their legal name, we assume they filled out
    their dating profile accurately. 

    Effect: the dating app intends to suggest a match to the person
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

initiates(I, Action, displays_personal_info(Person, Company)) :-
    happens(I, Action, al(Person)),
    Action=action(create_account(legalname, Person, Company)),
    dating_app_company(Company).

1 { intends(I, suggested_match(Company, Person, Match), Company) : person(Match) } :-
    happens(I, Action, al(Person)),
    Action=action(create_account(Name, Person, Company)).

%*  suggest_match(Company, Person1, Person2)
    A dating app can suggest a match, Person2, to Person1

    Preconditions: They both have accounts on the app, they are both in the
    same location, and the app has not suggested this match to Person1 before

    Effect: The app has now suggested this match to Person1

    Effect: If Person2 displayed real information about themselves, Person1 now
    knows Person2 is trying to find a date
    
    Effect: If Person1 knows Person2 is trying to find a date, Person1 knows
    Person2 is dating someone else, and they know Person2, Person1 now intends
    to accuse Person2 of cheating
*%
possible(I, action(suggest_match(Company, Person1, Person2)), al(Company)) :-
    id(I),
    dating_app_company(Company),
    person(Person1),
    person(Person2),
    Person1 != Person2,
    strong_holds(I, has_account(_, Person1, Company)),
    strong_holds(I, has_account(_, Person2, Company)),
    strong_holds(I, at_location(Person1, Location)),
    strong_holds(I, at_location(Person2, Location)),
    not strong_holds(I, suggested_match(Company, Person1, Person2)).

initiates(I, Action, suggested_match(Company, Person1, Person2)) :-
    happens(I, Action, al(Company)),
    Action=action(suggest_match(Company, Person1, Person2)).

initiates(I, Action, knows_finding_date(Person1, Person2)) :-
    happens(I, Action, al(Company)),
    Action=action(suggest_match(Company, Person1, Person2)),
    strong_holds(I, displays_personal_info(Person2, Company)).

intends(I, accused_of_cheating(Person1, Person2), Person1) :-
    happens(I, Action, al(Company)),
    Action=action(suggest_match(Company, Person1, Person2)),
    strong_holds(I, displays_personal_info(Person2, Company)),
    strong_holds(I, knows(Person1, Person2)),
    strong_holds(I, knows_dating(Person1, Person2, _)).

%*  see_profile(Person1, Person2, Company)
    Person1 can look at Person2's dating profile if the dating app suggested
    the match to Person1

    Preconditions: the app suggested this match to Person1

    Effect: Person1 now knows info on Person2's dating profile

    Effect: If Person2 used real personal info, we will assume that their
    dating profile outs them to Person1 if they're queer

    Effect: if Person2 has been outed, Person1 is queerphobic, and the
    conditions have been met, Person1 now intends to harass Person2 in real life
*%
possible(I, action(see_profile(Person1, Person2, Company)), al(Person1)) :-
    id(I),
    person(Person1),
    person(Person2),
    Person1 != Person2,
    dating_app_company(Company),
    strong_holds(I, suggested_match(Company, Person1, Person2)).

initiates(I, Action, knows_profile(Person1, Person2, Company)) :-
    happens(I, Action, al(Person1)),
    Action=action(see_profile(Person1, Person2, Company)).

initiates(I, Action, outed_to(Person2, Person1)) :-
    happens(I, Action, al(Person1)),
    Action=action(see_profile(Person1, Person2, Company)),
    queer(Person2).

intends(I, harassed_irl(Person1, Person2), Person1) :-
    happens(I, Action, al(Person1)),
    Action=action(see_profile(Person1, Person2, Company)),
    queer(Person2),
    queerphobic(Person1),
    strong_holds(I, at_location(Person1, Location)),
    strong_holds(I, at_location(Person2, Location)),
    strong_holds(I, knows(Person1, Person2)).

%*  accuse_of_cheating(Accuser, Accused)
    Someone can accuse another person of cheating

    Preconditions: the Accuser knows the Accused and they know they're dating
    someone

    Effect: the Accuser has now accused the Accused
*%
possible(I, action(accuse_of_cheating(Accuser, Accused)), al(Accuser)) :-
    id(I),
    person(Accuser),
    person(Accused),
    Accuser != Accused,
    strong_holds(I, knows(Accuser, Accused)),
    strong_holds(I, knows_dating(Accuser, Accused, _)).

initiates(I, Action, accused_of_cheating(Accuser, Accused)) :-
    happens(I, Action, al(Accuser)),
    Action=action(accuse_of_cheating(Accuser, Accused)).

%*  harass_irl(Harasser, Victim)
    A person can harass another person in real life

    Preconditions: the people are in the same location and they know each other

    Effect: they have now been harassed in real life
*%
possible(I, action(harass_irl(Harasser, Victim)), al(Harasser)) :-
    id(I),
    person(Harasser),
    person(Victim),
    Harasser != Victim, 
    strong_holds(I, at_location(Harasser, Location)),
    strong_holds(I, at_location(Victim, Location)),
    strong_holds(I, knows(Harasser, Victim)),
    strong_holds(I, knows(Victim, Harasser)).

initiates(I, Action, harassed_irl(Harasser, Victim)) :-
    happens(I, Action, al(Harasser)),
    Action=action(harass_irl(Harasser, Victim)).

%% Query Specification

% alice and bob both intend to use tinder
intends(start, has_account(legalname, alice, tinder), alice).
intends(start, has_account(legalname, bob, tinder), bob).
intends(start, has_account(legalname, carol, tinder), carol).

% alice and bob both intend for carol to know they're dating
intends(start, knows_dating(carol, bob, alice), alice).
intends(start, knows_dating(carol, bob, alice), bob).

% look for a solution that contains one person who intends to harass another
% person irl
:- not 1 { intends(I, harassed_irl(Person1, Person2), Person1) :
           id(I), person(Person1), person(Person2) }.

% Use total order
totalorder.

% Number of vertices in the resulting graph:
#const tmax=12.

% Information to be displayed:
#show happens/3.
#show edge/2.
#show satisfies/2.
#show intends/3.
#show strong_holds/2.
#show strong_notholds/2.