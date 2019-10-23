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

The DNS protocol {{!DNS=RFC1035}} provides no confidentiality; and therefore no privacy protections for queries.  Encryption of DNS transport between stub and recursive resolvers as defined in {{!DOT=RFC7858}} and {{!DOH=RFC8484}} provides confidentiality for DNS queries between a stub and a recursive resolver.

Recursive resolvers present a privacy dichotomy for clients.  A recursive resolver that aggregates queries from multiple clients provides a measure of anonymity for those clients, both for authoritative servers and from other observers on the network.  Aggregating requests from multiple clients makes it difficult for these entities to correlate queries with specific clients.  The potential for a recursive to answer queries from cache further improves this privacy advantage, while providing significant query latency gains.  However, because the recursive resolver sees and can record DNS queries, using a recursive resolver creates a privacy exposure for clients.

A client might decide to trust a particular recursive resolver with information about DNS queries.  However, it is difficult or impossible to provide any guarantees about data handling practices in the general case.  And even if a service can be trusted to respect privacy with respect to handling of query data, legal and commercial pressures or surveillance activity could result misuse of data.  Similarly, it is not possible to make any guarantees about attacks on services.  For a service with many clients, these risks are particularly undesirable.

This memo describes techniques for distributing DNS queries between multiple recursive resolvers from a known set.  The goal is to reduce the amount of information that any signal DNS resolver is able to gain and thereby reduce the amount of privacy-sensitive information that can be collected in one place.  The characteristics of different choices are examined.

An important outcome of this analysis is that simplistic methods for distributing queries -- such as a round-robin algorithm -- have considerably worse privacy characteristics than using a single recursive resolver.

The rest of this memo is organized as follows. {{goals}} specifies the requirements that we would like such a distribution arrangement to provide. {{algorithms}} discusses the different strategies, and makes some early recommendations among the strategies. {{furtherwork}} discusses potential further work in this area.

# Goals and Constraints {#goals}

This document aims to reduce the concentration of information about client activity by distributing DNS queries across different resolver services, for all DNS queries in the aggregate and for DNS queries made by individual clients.  By distributing queries in this way, the goal is to reduce the amount of information that any given DNS resolver service can acquire about client activity.

Any method for distributing queries from a single client needs to consider the risk of increasing the total amount of private information that is exposed by distributing queries -- and associated information -- to multiple DNS resolvers.  In the extreme, any design that results in replicating the same query toward multiple services would be a net privacy loss.  More subtle leaks arise as a result of distributing queries for sub-domains and even domains that are superficially unrelated, because these could share a commonality that might be exploited to link them.

For instance, some web sites use names that are appear unrelated to their primary name for hosting some kinds of content, like static images or videos.  If queries for these unrelated names were sent to different services, that effectively allows multiple resolvers to learn that the client accessed the web site.

A distribution scheme also needs to consider stability of query routing over time.  A resolver can observve the absence of queries and infer things about the state of a client cache, which can reveal that queries were made to other resolvers.

The need to limit replication of private information about queries eliminates simplistic distribution schemes, such as those discussed in {{bad-algorithms}}.

Note that there are also other possible goals, e.g., around discovery of DNS servers (see, e.g., {{I-D.schinazi-httpbis-doh-preference-hints}}). These goals are outside the scope of this memo, as it is only concerned with selection from a set of known servers.

# Query distribution algorithms {#algorithms}

This section introduces and analyzes several potential strategies for distributing queries to different resolvers. Each strategy is formulated as an algorithm for choosing a resolver Ri from a set of n resolvers R1, R2, ...,  Rn.

Note that the list of algorithms may grow in a future version of this memo; this set is the initially analyzed set.

The designs presented in {{algorithms}} assume that the stub resolver performing distribution of queries has varying degrees of contextual information.  In general, more contextual information allows for finer-grained distribution of information between resolvers.


## Client-based {#clientbased}

The simplest algorithm is to distribute each different client to a different resolver. This reduces the number of users any particular service will know about. However, in order to function properly, this methods needs to apply some kind of stable assignment mechanism, e.g., a stable hash.

One way of doing this is to hash the client's identity in some manner:

    i = h(client identity) % n

Note that the client identity can (and should) be something that remains private to the client itself; the resolver service need not be told about the identity, even if the client's concept of its own identity leads it to select a particular resolver service. To avoid disclosing DNS usage patterns to all resolvers, the identity needs to be persistent information, perhaps obtained from the operating system, user account, hardware, or a random value chosen upon the first use of the application.

While this algorithm satisfies the first overall goal in {{goals}}, it does nothing about splitting information regarding a particular client to different services. The only privacy benefit it provides is that it reduces the number of clients that each resolver service provider has information about. This may discourage attacking that service, or forcing the service to give out information. But for each individual client, there is still some resolver service that knows everything about the user's DNS usage patterns.

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

The authors would like to thank Christian Huitema, Ari Keränen, Mark Nottingham, Stephen Farrell, Gonzalo Camarillo, Mirja Kühlewind, David Allan, Daniel Migault and many others for interesting discussions in this problem space.

--- back

# Poor distribution algorithms {#bad-algorithms}

This appendix examines some of the drawbacks of simple distribution schemes.

## Random

A per-query random allocation to a resolver might be implemented:

    i = rand() % n

This has the drawback of providing information about all clients to all services over time. While this happens slowly, and does not affect names that are not regularly visited, it still seems to be a serious problem in this approach.

## Round-robin

The clients can also choose to use a new resolver service either for every query or upon client boot:

    i = counter++ % n

This has largely the same downsides as the random algorithm.
