%* This file describes a narrative space relating to internet surveillence,
   inspired by the UK's Investigatory Powers Act. 

   Alice is questioning and would like to explore queer spaces on social media,
   without anyone else knowing. Bob, Alice's father, wants to know about Alice's
   online activity. Alice and Bob are in the UK, which records all internet
   activity in the country, and Bob can potentially access this information as a
   government worker.
*%

%% Facts

person(alice; bob).
queer(alice).
:- queer(Person), not person(Person). % Sanity check: all queer people are people

gov(uk).

content_type(queer; other).


%% Initial State

% These properties hold at the start, and they continue to hold until they are
% terminated by an action:
strong_holds(start, works_for(bob, uk)).

% These properties do not hold at the start, and they continue to not hold until
% they are initiated by an action:
strong_notholds(start, data_secure(Gov)) :- gov(Gov).
strong_notholds(start, uses_tor(Person)) :- person(Person).

%% Pool of Possible Actions

%*  create_account(Person)
    A person can create a social media account.

    Preconditions: None

    Effect: the person now has an account
*%
possible(I, action(create_account(Person)), al(Person)) :-
    id(I),
    person(Person).

initiates(I, Action, has_account(Person)) :-
    happens(I, Action, al(Person)),
    Action=action(create_account(Person)).

%*  access_content(Person, Type, I)
    A person can access content of any type on social media at a moment in time.

    Preconditions: the person has a social media account

    Effect: the person has now accessed queer content
    
    Effect: if they don't use Tor, the government now intends to record their
    use of the internet
*%
possible(I, action(access_content(Person, Type, I)), al(Person)) :-
    id(I),
    person(Person),
    content_type(Type),
    strong_holds(I, has_account(Person)).

initiates(I, Action, accessed_internet(Person, Type, I)) :-
    happens(I, Action, al(Person)),
    Action=action(access_content(Person, Type, I)).

intends(I, recorded_internet_access(Gov, Person, Type, I), Gov) :- 
    happens(I, Action, al(Person)),
    Action=action(access_content(Person, Type, I)),
    gov(Gov),
    strong_notholds(I, uses_tor(Person)).

%*  attend_workshop(Person)
    A person can attend a privacy workshop.

    Preconditions: None

    Effect: the person now uses Tor
*%
possible(I, action(attend_workshop(Person)), al(Person)) :-
    id(I),
    person(Person).

initiates(I, Action, uses_tor(Person)) :-
    happens(I, Action, al(Person)),
    Action=action(attend_workshop(Person)).

%*  record_internet_access(Gov, Person, Type, AccI)
    A government can record a person's use of the internet.

    Preconditions: the person accessed the internet and was not using Tor at the
    time

    Effects: the internet access is recorded
*%
possible(I, action(record_internet_access(Gov, Person, Type, AccI)), al(Gov)) :-
    id(I),
    gov(Gov),
    person(Person),
    content_type(Type),
    id(AccI),
    strong_notholds(AccI, uses_tor(Person)),
    strong_holds(I, accessed_internet(Person, Type, AccI)).

initiates(I, Action, recorded_internet_access(Gov, Person, Type, AccI)) :-
    happens(I, Action, al(Gov)),
    Action=action(record_internet_access(Gov, Person, Type, AccI)).

%*  see_recorded_internet_usage(Govworker, Victim, Type)
    A person who works with government data can see the recorded internet use
    of another person.

    Preconditions: the victim's usage was recorded, the initiator works for the
    government that recorded the access, and this government does not keep the
    data secure

    Effect: the initiator knows how the victim uses the internet
    
    Effect: if the victim had previously accessed queer content, they become
    outed to the intiator. 
*%
possible(I, action(see_recorded_internet_usage(Govworker, Victim, Type)), al(Govworker)) :-
    id(I),
    person(Govworker),
    person(Victim),
    Govworker != Victim,
    gov(Gov),
    strong_holds(I, works_for(Govworker, Gov)),
    strong_notholds(I, data_secure(Gov)),
    content_type(Type),
    strong_holds(I, recorded_internet_access(Gov, Victim, Type, _)).

initiates(I, Action, knows_internet_usage(Govworker, Victim)) :-
    happens(I, Action, al(Govworker)),
    Action=action(see_recorded_internet_usage(Govworker, Victim, Type)).

initiates(I, Action, outed_to(Victim, Govworker)) :-
    happens(I, Action, al(Govworker)),
    Action=action(see_recorded_internet_usage(Govworker, Victim, queer)).


%% Query Specification

% Alice's intentions: access queer content at least once, without anyone else
% knowing
1 { intends(start, accessed_internet(alice, queer, I), alice) : id(I) }.
intends(start, never_holds(outed_to(alice, bob)), alice).

% Bob's intentions: know what Alice does on the Internet
intends(start, knows_internet_usage(bob, alice), bob).

% Alice specifically wants to access queer content and not get outed in a single
% timeline
% TODO
%*
:- id(I),
   satisfies(I, intention(start, accessed_internet(alice, queer, I)), alice),
   not satisfies(C, intention(start, never_holds(outed_to(alice, bob))), alice) : concludes(C, I).
*%

% make sure alice attends the workshop at least once
 1 { happens(I, action(attend_workshop(alice)), al(alice)) : id(I) }.

% Use total order
totalorder.

% Number of vertices in the resulting graph:
#const tmax=8.

% Information to be displayed: 
#show happens/3.
#show edge/2.
#show satisfies/2.
#show intends/3.
#show strong_holds/2.
#show strong_notholds/2.