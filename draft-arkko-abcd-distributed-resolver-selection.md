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

The designs presented in {{algorithms}} assume that the stub resolver performing distribution of queries has varying degrees of contextual information.  In general, more contextual information allows for finer-grained distribution of information between resolvers.


## Client-based {#clientbased}

The simplest algorithm is to distribute each different client to a different resolver. This reduces the number of users any particular service will know about.  However, this does little to protect an individual user from the aggregation of information about queries at the selected resolver.

In this design clients select and consistently use the same resolver.  This might be achieved by randomly selecting and remembering a resolver.  Alternatively, a resolver might be selected using consistent hashing that takes some conception of client identity as input:

    i = h(client identity) % n

For the purposes of this determination, a client might be an entire device, with the selection being made at the operating system level, or it could be a selection made by individual applications.  In the extreme, an individual application might be able to partition its activities in a way that allows it to direct queries to multiple resolvers.

### Analysis of client-based selection

Where different applications make independent resolver selections, activities that involve multiple applications can result in information about those activities being exposed to multiple resolvers.  For instance, an application could open another application for the purposes of handling a specific file type or to load a URL.  This could expose queries related to the activity as a whole to multiple resolvers.

Even making different selections at the level of a device can result in replicating related information to multiple resolvers.  For instance, an individual who uses a particular application on multiple devices might perform similar activities on those devices, but have DNS queries distributed to different resolvers.

While this algorithm provides distribution of DNS queries in the aggregate, it does little to divide information about a particular client between resolvers. It effectively only reduces the number of clients that each resolver can acquire information about. This provides systemic benefit, but does not provide individual clients with any significant advantage as there is still some resolver service that has a complete view of the user's DNS usage patterns.

### Enhancements to client-based selection {#discontinuous}

Clients can break continuity of records by occasionally resetting state so that a different resolver is selected.  A client might choose to do this when it shuts down, or when it moves to a new network location.

Breaking continuity is less effective if any state, in particular cached results, is retained across the change.  If activities that depend on DNS querying are continued across the change then it might be possible for the old resolver to make inferences about the activity on the new resolver, or the new resolver to make similar guesses about past activity.  As many modern applications provide session continuity features across shutdowns and crashes, this can mean that finding an appropriate point in time to perform a switch.

## Name-based {#namebased}

Clients might also additionally attempt to distribute queries based on the name being queried.  This results in different names going to different resolvers.

A naïve algorithm for name distribution uses the target name as input to a fixed hash:

    i = h(queried name) % n

However, this simplistic approach fails to prevent related queries from being distributed to different resolvers in several ways.  For instance, queries that are executed after receiving a CNAME record in a response will leak the same information as the original query that resulted in the CNAME record.  Services that use related domain names -- such as where "example.com" uses "static.example.com" or "cdn.example" -- might reveal the use of the combined service to a resolver that receives a query for any associated name.  In both cases, sensitive information is effectively replicated across multiple resolvers.

### Name reduction

In order to reduce the effect of distributing similar names to different servers, a grouping mechanism might be used.  Leading labels in names might be erased before being input to the hashing algorithm.  This requires that the part of the suffix that is shared between different services can be identified.  For the purposes of ensuring that queries are consistently routed to the same resolver, a weak signal is likely sufficient.

Several options for grouping domain names into equivalence sets might be used:

* The [public suffix list](https://publicsuffix.org/) provides a manually curated list of shared domain suffixes.  Names can be reduced to include one label more than the list allows, referred to as effective top-level domain plus one (eTLD+1).  This reduces the number of cases where queries for domains under the same administrative control are sent to different resolvers.

* Services often relies on multiple domain names across different eTLD+1 domains.  Developing equivalence sets might be needed to avoid broadcasting queries to servers.  Mozilla maintains a manually curated [equivalence list](https://github.com/mozilla-services/shavar-prod-lists/blob/master/disconnect-entitylist.json) for web sites that aims to maps the complete set of unrelated names used by services to a single service name.

* Other technologies, such as the proposed [first party sets](https://github.com/krgovind/first-party-sets) or the abandoned DBOUND {{?DBOUND=I-D.levine-dbound-dns}} provide domain owners a means to declare some form of equivalence for different names.

Each of these techniques are potentially unreliable in different ways.  Additionally, these could skew the distribution of queries in ways that might concentrate information on particular resolvers.

# Effects of query distribution

Choosing to use more than one DNS resolver has broader implications than just the effect on privacy.

## Caching considerations {#caching}

Using a common cache for multiple resolvers introduces the possibility that a resolver could learn about queries that were originally directed to another resolvers by observing the absence of queries.  Though this can reduce caching performance, clients can address this by having a per-resolver cache and only using the cache for the selected resolver.

## Consistency considerations

Making the same query to multiple resolvers can result in different answers.  For instance, DNS-based load balancing can lead to different answers being produced over time or for different query origins.

In the extreme, an application might encounter errors as a result of receiving incompatible answers, particularly if a server operator (incorrectly) assumes that different DNS queries for the same client always originate from the same source address.  This is most likely to occur if name-based selection is used, as queries could be related based on information that the client does not consider.

## Resolver load distribution

Any selection of resolvers that is based on random inputs will need to account for available capacity on resolvers.  Otherwise, resolvers with less available query-processing capacity will receive too high a proportion of all queries.  Clients only need to be informed of relative available capacity in order to make an appropriate selection.  How relative capacities of resolvers are determined is not in scope for this document.

# Poor distribution algorithms {#bad-algorithms}

Random allocation to a resolver might be implemented:

    i = rand() % n

Similar drawbacks can be seen where clients iterate over available resolvers:

    i = counter++ % n

Whether this choice is made on a per-query basis, these two methods eventually provide information about all queries to all resolvers over time.  Domain names are often queried many times over long periods, so queries for the same domain name will eventually be distributed to all resolvers.  Only one-off queries will avoid being distributed.

Implementing either method at a much slower cadence might be effective, subject to the constraints in {{discontinuous}}.  This only slows the distribution of information about repeated queries to all resolvers.

# Further work {#furtherwork}

TBD

--- back

# Acknowledgements {#ack}

The authors would like to thank Christian Huitema, Ari Keränen, Mark Nottingham, Stephen Farrell, Gonzalo Camarillo, Mirja Kühlewind, David Allan, Daniel Migault and many others for interesting discussions in this problem space.
