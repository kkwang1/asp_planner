%* This file describes a narrative space relating to internet surveillence,
   inspired by the UK's Investigatory Powers Act. 

   Alice is questioning and would like to explore queer spaces online, without
   anyone else knowing. Bob, Alice's father, wants to know about Alice's
   online activity. Alice and Bob are in the UK, which records all internet
   activity in the country, and Bob can potentially access this information as a
   government worker.
*%

person(alice;bob).
gov(uk).


%% Initial State

% Alice would like to access LGBTQ content at least once, and she would not want
% Bob to know
1 {intends(start, accessed_lgbtq_content(alice, AccTime), alice) : id(AccTime)}.
intends(start, not_suspicious(bob, alice), alice).

% Bob would like to know what Alice does on the Internet
intends(start, knows_content(bob, alice), bob).

% These properties hold at the start, and they continue to hold until they are
% terminated by an action:
strong_holds(start, works_for(bob, uk)).
strong_holds(start, not_suspicious(Person1, Person2)) :- person(Person1), person(Person2).

% These properties do not hold at the start, and they continue to not hold until
% they are initiated by an action:
strong_notholds(start, knows_content(Person1, Person2)) :- person(Person1), person(Person2).
strong_notholds(start, has_account(Person)) :- person(Person).
strong_notholds(start, accessed_lgbtq_content(Person, I)) :- person(Person), id(I).
strong_notholds(start, recorded_lgbtq_content(Gov, Person, I)) :- person(Person), gov(Gov), id(I).
strong_notholds(start, uses_tor(Person)) :- person(Person).
strong_notholds(start, data_secure(Gov)) :- gov(Gov).


%% Pool of Possible Actions

% A person can create a social media account
%   Preconditions: None
%   Effects: the person now has an account
possible(I, action(create_account(Person)), al(Person)) :-
    id(I),
    person(Person).
initiates(I, Action, has_account(Person)) :-
    happens(I, Action, al(Person)),
    Action=action(create_account(Person)).

% A person can access LGBTQ content on social media
%   Preconditions: the person has a social media account
%   Effects: the person has now accessed LGBTQ content, and the government now
%   intends to record their use of the internet
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

% A person can attend a privacy workshop
%   Preconditions: None
%   Effects: the person now uses Tor
possible(I, action(attend_workshop(Person)), al(Person)) :-
    id(I),
    person(Person).
initiates(I, Action, uses_tor(Person)) :-
    happens(I, Action, al(Person)),
    Action=action(attend_workshop(Person)).

% A government can record a person's use of the internet
%   Preconditions: the person accessed the internet and was not using Tor at the
%   time
%   Effects: the internet access is recorded
possible(I, action(record_lgbtq_content(Gov, Person, AccTime)), al(Gov)) :-
    id(I),
    gov(Gov),
    person(Person),
    strong_notholds(AccTime, uses_tor(Person)),
    strong_holds(I, accessed_lgbtq_content(Person, AccTime)).
initiates(I, Action, recorded_lgbtq_content(Gov, Person, AccTime)) :-
    happens(I, Action, al(Gov)),
    Action=action(record_lgbtq_content(Gov, Person, AccTime)).

% A person can see the recorded internet use of another person
%   Preconditions: the victim's usage was recorded, the initiator works for the
%   government that recorded the access, and this government does not keep the
%   data secure
%   Effects: the initiator knows how the victim uses the internet, and they
%   become suspicious if the access was LGBTQ-related.
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


%% Query Specification

% :- not Expr, Expr = 1 { happens(I, action(attend_workshop(alice)), al(alice)) : id(I) }.

% Number of vertices in the resulting graph:
#const tmax=10.

% Information to be displayed: 
#show happens/3.
#show edge/2.
#show satisfies/2.
#show intends/3.
#show strong_holds/2.
#show strong_notholds/2.