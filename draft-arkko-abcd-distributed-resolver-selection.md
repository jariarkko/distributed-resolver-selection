---
title: Selecting Resolvers from a Set of Distributed DNS Resolvers
abbrev: Distributed Resolver Selection
docname: draft-arkko-abcd-distributed-resolver-selection
date:
category: info

ipr: trust200902
keyword: Internet-Draft

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
  -
    ins: J. Arkko
    name: Jari Arkko
    org: Ericsson
    email: jari.arkko@piuha.net
  -
    ins: M. Thomson
    name: Martin Thomson
    org: Mozilla
    email: martin.thomson@gmail.com
  -
    ins: T. Hardie
    name: Ted Hardie
    org: Google
    email: ted.ietf@gmail.com

normative:

informative:
  RFC7258:
  I-D.schinazi-httpbis-doh-preference-hints:
  MSCVUS:
   title: Microsoft Corp. v. United States
   author:
    - ins: Wikipedia
   seriesinfo: https://en.wikipedia.org/wiki/Microsoft_Corp._v._United_States

--- abstract

This memo discusses the use of a set of different DNS resolvers to reduce privacy problems related to resolvers learning the Internet usage patterns of their clients.

--- middle

# Introduction {#introduction}

Internet communications are increasingly protected by use of encryption {{?TLS13=RFC8446}}, {{?QUIC=I-D.ietf-quic-transport}}, {{?ESNI=I-D.ietf-tls-esni}}.

Encryption of DNS transport between stub and recursive resolvers is defined in {{!DOT=RFC7858}} and {{!DOH=RFC8484}}.  These protocols provide confidentiality for DNS queries to a recursive resolver.

Recursive resolvers present a privacy dichotomy for clients.  A recursive resolver that aggregates queries from multiple clients provides a measure of anonymity for those clients, both for authoritative servers and from other observers on the network.  Aggregating requests from multiple clients makes it difficult for these entities to correlate queries with specific clients.  The potential for a recursive to answer queries from cache further improves this privacy advantage, while providing significant query latency gains.  However, because the recursive resolver sees and can record DNS queries, using a recursive resolver creates a privacy exposure for clients.

A client might decide to trust a particular recursive resolver with information about DNS queries.  However, it is difficult or impossible to provide any guarantees about data handling practices in the general case.  And even if a service can be trusted to respect privacy with respect to handling of query data, legal and commercial pressures or surveillance activity could result misuse of data.  Similarly, it is not possible to make any guarantees about attacks on services.  For a service with many clients, these risks are particularly undesirable.

Defending against privacy leaks for DNS queries is particularly important given the prevalence of pervasive surveillance efforts {{RFC7258}}.

This memo describes techniques for distributing DNS queries between multiple recursive resolvers from a known set.  The goal is to reduce the amount of information that any signal DNS resolver is able to gain and thereby reduce the amount of privacy-sensitive information that can be collected in one place.  The characteristics of different choices are examined.

An important outcome of this analysis is that simplistic methods for distributing queries -- such as a round-robin algorithm -- have considerably worse privacy characteristics than using a single recursive resolver.

There are many other worthwhile topics in the general space of providing better confidentiality or privacy for DNS queries, or for operating encrypted DNS query services. Topics such as resolver discovery, operational practices at any individial resolver service, etc. are outside the scope of this memo.

The rest of this memo is organized as follows. {{goals}} specifies the requirements that we would like such a distribution arrangement to provide. {{algorithms}} discusses the different strategies, and makes some early recommendations among the strategies. {{furtherwork}} discusses potential further work in this area.

# Goals {#goals}

There are many possible goals for building distributed services, with the most typical one being the ability to scale to be able to serve large number of clients. This memo is not focused on this aspect, but rather looks at distributing queries to different resolver service providers to provide privacy benefits.

The background for looking at different service providers is that it is unlikely that there are significant difference with regards to privacy issues within the same provider, even if its servers are distributed in different locations. Any technical vulnerabilities or commercial objectives apply throughout such networks anyway, and government and surveillance activities seem to have extraterritorial reach (see, e.g., {{MSCVUS}}).

As a result, the main privacy question is how to reduce information learned by any individual resolver service provider through distribution of queries from different clients.

Some of the basic goals that this distribution should achieve include:

* Not concentrating information from all clients to a single resolver service.

* Reducing the information given out regarding a single client to any individual resolver service.

The latter goal can be broken further down to:

* Avoiding sending queries about the same destination to different services, as otherwise the result is worse than not doing any distribution at all: all the different services will eventually get the same information about a particular client.

* Avoiding sending queries about related destinations (*.example.com) to different services, as otherwise the different services will likely conclude that the client is using the "example.com" service anyway, regardless of the individual sub-domains accessed on specific requests.

* For browsers, avoiding sending queries about destinations on the same page (https://example.com pulls an image from https://anotherexample.com) to different servers. This is because there is a possibility of correlation that  lets someone determine that the user was on that page.

* Otherwise, sending queries about different things to different servers, to keep each server aware of minimal information about a particular client.

Some of these goals depend on which component in a system is performing the queries. The web page goal above can only be done by browsers, whereas the other rules could also be implemented in an OS-based resolver client.

Note that there are also other possible goals, e.g., around discovery of DNS servers (see, e.g., {{I-D.schinazi-httpbis-doh-preference-hints}}). These goals are outside the scope of this memo, as it is only concerned with selection from a set of known servers.

# Potential selection algorithms {#algorithms}

This section introduces and analyzes several potential strategies for distributing queries to different resolvers. Each strategy is formulated as an algorithm for choosing a resolver Ri from a set of n resolvers R1, R2, ...,  Rn.

Note that the list of algorithms may grow in a future version of this memo; this set is the initially analyzed set.

## Client-based {#clientbased}

The simplest algorithm is to distribute each different client to a different resolver. This reduces the number of users any particular service will know about. However, in order to function properly, this methods needs to apply some kind of stable assignment mechanism, e.g., a stable hash.

One way of doing this is to hash the client's identity in some manner:

    i = h(client identity) % n

Note that the client identity can (and should) be something that remains private to the client itself; the resolver service need not be told about the identity, even if the client's concept of its own identity leads it to select a particular resolver service. To avoid disclosing DNS usage patterns to all resolvers, the identity needs to be persistent information, perhaps obtained from the operating system, user account, hardware, or a random value chosen upon the first use of the application.

While this algorithm satisfies the first overall goal in {{goals}}, it does nothing about splitting information regarding a particular client to different services. The only privacy benefit it provides is that it reduces the number of clients that each resolver service provider has information about. This may discourage attacking that service, or forcing the service to give out information. But for each individual client, there is still some resolver service that knows everything about the user's DNS usage patterns.

## Random

Another simple algorithm is a random selection:

    i = rand() % n

This has the drawback of (over-time) providing information about all clients to all services. While this happens slowly, and does not affect names that are not regularly visited, it still seems to be a serious problem in this approach.

## Round-robin

The clients can also choose to use a new resolver service either for every query or upon client boot:

    i = counter++ % n

This has largely the same downsides as the random algorithm.

## Name-based {#namebased}

The clients may distribute their queries based on the name being queried. This results in different names going to different services, e.g., a social network name goes to a different service than a search engine name:

    i = h(queried name) % n

This approach may also be extended to cover moving hosts by incorporating the public IP address of the host, such that when the host moves, the distribution changes. For this to work the DNS query protocol must not be fingerprintable. Similarly, one may also include the client id as in the {{clientbased}} approach. The full equation for all of these is:

    i = h(client identity|queried name|client public address) % n

When the hash function only takes into account the name and nothing else, different clients will algorithmically arrive at the use of the same resolver for the same names. This can be undesirable. When address and identity information is used alongside the name, this is no longer a problem.

Note that any hash-based distribution to a set of resolvers may or may not distribute traffic to the resolvers equally. For instance, a popular domain may get a lot of queries, but is just one name from the point of view of the hash. Further work may be needed on this.

## Suffix-based

A variant of the {{namebased}} approach is that one does not consider the full name, but rather the main domain, i.e., example.com rather than www.example.com. To do this, one can use a public suffix list that provides information about commonly used domain names.

The equation then becomes:

    i = h(client identity|organization suffix of the queried name|
          client public address) %  n

## Early recommendations

The name- and suffix-based approaches seem to be more capable than random- or round-robin -based approaches.

# Further work {#furtherwork}

TBD

# Acknowledgements {#ack}

The authors would like to thank Christian Huitema, Ari Keranen, Mark Nottingham, Stephen Farrell, Gonzalo Camarillo, Mirja Kuhlewind, David Allan, Daniel Migault and many others for interesting discussions in this problem space.
