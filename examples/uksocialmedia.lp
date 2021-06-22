% Actors
person(alice;bob).
gov(uk).
1 {intends(start, accessed_lgbtq_content(alice, AccTime), alice) : id(AccTime)}.
% Unsatisfiable when the following is uncommented: 
% intends(start, not_suspicious(bob, alice), alice).
intends(start, knows_content(bob, alice), bob).

% Initial state
strong_holds(start, works_for(bob, uk)).
strong_holds(start, not_suspicious(Person1, Person2)) :- person(Person1), person(Person2).
strong_notholds(start, knows_content(Person1, Person2)) :- person(Person1), person(Person2).
strong_notholds(start, has_account(Person)) :- person(Person).
strong_notholds(start, accessed_lgbtq_content(Person, I)) :- person(Person), id(I).
strong_notholds(start, recorded_lgbtq_content(Gov, Person, I)) :- person(Person), gov(Gov), id(I).
strong_notholds(start, uses_tor(Person)) :- person(Person).
strong_notholds(start, data_secure(Gov)) :- gov(Gov).

% Actions
possible(I, action(create_account(Person)), al(Person)) :-
    id(I),
    person(Person).
initiates(I, Action, has_account(Person)) :-
    happens(I, Action, al(Person)),
    Action=action(create_account(Person)).

possible(I, action(access_lgbtq_content(Person, I)), al(Person)) :-
    id(I),
    person(Person),
    strong_holds(I, has_account(Person)).
initiates(I, Action, accessed_lgbtq_content(Person, AccTime)) :-
    happens(I, Action, al(Person)),
    Action=action(access_lgbtq_content(Person, AccTime)).
intends(I, recorded_lgbtq_content(Gov, Person, I), Gov) :- 
    gov(Gov),
    happens(I, Action, al(Person)),
    Action=action(access_lgbtq_content(Person, I)),
    strong_notholds(I, uses_tor(Person)).

possible(I, action(attend_workshop(Person)), al(Person)) :-
    id(I),
    person(Person).
initiates(I, Action, uses_tor(Person)) :-
    happens(I, Action, al(Person)),
    Action=action(attend_workshop(Person)).

possible(I, action(record_lgbtq_content(Gov, Person, AccTime)), al(Gov)) :-
    id(I),
    gov(Gov),
    person(Person),
    strong_notholds(AccTime, uses_tor(Person)),
    strong_holds(I, accessed_lgbtq_content(Person, AccTime)).
initiates(I, Action, recorded_lgbtq_content(Gov, Person, AccTime)) :-
    happens(I, Action, al(Gov)),
    Action=action(record_lgbtq_content(Gov, Person, AccTime)).

possible(I, action(see_recorded_lgbtq_content(Govworker, Person)), al(Govworker)) :-
    id(I),
    person(Person),
    person(Govworker),
    gov(Gov),
    strong_holds(I, works_for(Govworker, Gov)),
    strong_notholds(I, data_secure(Gov)),
    strong_holds(I, recorded_lgbtq_content(Gov, Person, _)).
initiates(I, Action, knows_content(Govworker, Person)) :-
    happens(I, Action, al(Govworker)),
    Action=action(see_recorded_lgbtq_content(Govworker, Person)).
terminates(I, Action, not_suspicious(Govworker, Person)) :-
    happens(I, Action, al(Govworker)),
    Action=action(see_recorded_lgbtq_content(Govworker, Person)).

% :- not Expr, Expr = 1 { happens(I, action(attend_workshop(alice)), al(alice)) : id(I) }.

#const tmax=10.

#show happens/3.
#show edge/2.
#show satisfies/2.
#show intends/3.
#show strong_holds/2.
#show strong_notholds/2.