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

The DNS {{!DNS=RFC1035}} is a complex system with many different security issues, challenges, deployment models and usage patterns. This document focuses on one narrow aspect within DNS and its security.

Traditionally, systems are configured with a single DNS recursive resolver, or a set of primary and alternate recursive resolvers. Recursive resolver services are offered by organisations such as enterprises, ISPs, and global providers. Even when clients use alternate recursive resolvers, they are typically all provided by the same organisation.

The resolvers will learn the Internet usage patterns of their clients. A client might decide to trust a particular recursive resolver with information about DNS queries. However, it is difficult or impossible to provide any guarantees about data handling practices in the general case. And even if a service can be trusted to respect privacy with respect to handling of query data, legal and commercial pressures or surveillance activity could result in misuse of data. Similarly, outside attacks may occur towards any DNS services. For a service with many clients, these risks are particularly undesirable.

This memo discusses whether DNS clients can improve their privacy through the potential use of a set of multiple recursive resolver services. The goal is indeed an improvement only. There is no expectation that it would be possible to have no part of the DNS infrastructure aware of what queries are being made, but perhaps there are mitigations that would make possible information collection from the DNS infrastruture harder.

It should be understood that this is a narrow aspect within a bigger set of topics even within privacy issues around DNS, let alone other security issues, deployment models, or the many protocol questions within DNS. Some of these other topics include detecting the tampering DNS query responses {{!DNSSEC=RFC4033}}, encrypting DNS queries {{!DOT=RFC7858}} {{!DOH=RFC8484}}, application-specific DNS resolution mechanisms, or centralised deployment models. Those other topics are not covered in this memo and need to be dealt with elsewhere.

Specifically, the scope of this memo is not limited to DNS-over-TLS (DOT) or DNS-over-HTTPS (DOH) deployments nor does it take a stand on operating system vs. application or local vs. centralized DNS deployment models. This memo is intended to provide useful information for those that wish to consider trustworthiness of their recursive resolvers as a part of their privacy analysis.

Naturally, there are some interactions between different topics. For instance, privacy is affected both by what happens to data in transit and at the endpoints, so where privacy is a concern, one would expect to consider both aspects, and lack of consideration on one probably leads to issues that dwarf the problems that this memo can address. Both issues are also important aspects when considering defense again pervasive monitoring efforts {{!PMON=RFC7258}}.

The rest of this memo is organized as follows. {{opscontext}} discusses the operational context that we imagine the multiple recursive resolver arrangement might be applied in. {{goals}} specifies security goals for a system that employs multiple recursive resolvers.

One key aspect of a system using multiple resolvers would be how to select which particular recursive resolver to use in a particular situation. This is discussed in {{algorithms}}. This section covers a number of possible strategies and further considerations for this selection, along with an analysis of the implications of choosing a particular strategy. There are technical issues in the use of multiple recursive resolvers, and there are both technical and non-technical questions in deciding on what recursive resolvers should even be in the set.

Some early recommendations are provided in {{conclusions}}. {{effects}} discusses operational and other implications of the distributed approach. Finally, {{furtherwork}} discusses potential further work in this area.

# Operational Context {#opscontext}

Our perspective is that of a client, choosing to either distribute or not distribute its queries to a set of different resolvers. And if the client decides to use distribution, it can choose exactly how it does that.

There are obviously additional operational aspect of this -- such as central configuration mechanisms, resolver selection application choices, and so on. But these are not covered in this memo.

It should also be observed that the practices suggested in this memo are currently not widely used. Operational and other issues may be discovered, such as those outlined in {{effects}}. 

Many of these issues need further work, but this memo aims to discuss the concept and analyse its impacts before dwelling into the technical arrangements for configuring and using this particular approach.

# Goals and Constraints {#goals}

This document aims to reduce the concentration of information about client activity by distributing DNS queries across different resolver services, for all DNS queries in the aggregate and for DNS queries made by individual clients.  By distributing queries in this way, the goal is to reduce the amount of information that any given DNS resolver service can acquire about client activity. As such, creates a benefit for the client, but also makes these resolvers less valuable targets for attacks relating to that client's activity.

Any method for distributing queries from a single client needs to consider these benefits with regards to the following constraints:

* A careful selection of the set of trusted resolvers must be the first priority. It does not make sense to add less trustworthy resolvers merely for the sake of distribution. For instance, there is no reason to mix resolvers with good reliability or high degree of privacy regulation with other resolvers: just include the best resolvers in the set.

* As the goal is to reduce the amount of information given to any given resolver, a strategy that tells the same information to all resolvers is a poor one. A design that results in replicating the same query toward multiple services would thus be a net privacy loss. This happens quite easily over a long period of time, unless the distribution method is carefully designed.

   More subtle leaks arise as a result of distributing queries for sub-domains and even domains that are superficially unrelated, because these could share a commonality that might be exploited to link them. For instance, some web sites use names that are appear unrelated to their primary name for hosting some kinds of content, like static images or videos.  If queries for these unrelated names were sent to different services, that effectively allows multiple resolvers to learn that the client accessed the web site.

A distribution scheme also needs to consider stability of query routing over time.  A resolver can observe the absence of queries and infer things about the state of a client cache, which can reveal that queries were made to other resolvers.

In effect, there are two goals in tension:

* to split queries between as many different resolvers as possible; and

* to reduce the spread of information about related queries across multiple resolvers.

The need to limit replication of private information about queries eliminates naive distribution schemes, such as those discussed in {{bad-algorithms}}.  The designs described in {{algorithms}} all attempt to balance these different goals using different properties from the context of a query ({{clientbased}}) or the query name itself ({{namebased}}).

# Query distribution strategies {#algorithms}

This section introduces and analyzes several potential strategies for distributing queries to different resolvers. Each strategy is formulated as an algorithm for choosing a resolver Ri from a set of n resolvers R1, R2, ...,  Rn.

The designs presented in {{algorithms}} assume that the stub resolver performing distribution of queries has varying degrees of contextual information.  In general, more contextual information allows for finer-grained distribution of information between resolvers.

## Client-based {#clientbased}

The simplest strategy is to distribute each different client to a different resolver. This reduces the number of users any particular service will know about.  However, this does little to protect an individual user from the aggregation of information about queries at the selected resolver.

In this design clients select and consistently use the same resolver.  This might be achieved by randomly selecting and remembering a resolver.  Alternatively, a resolver might be selected using consistent hashing that takes some conception of client identity as input:

    i = h(client identity) % n

For the purposes of this determination, a client might be an entire device, with the selection being made at the operating system level, or it could be a selection made by individual applications.  In the extreme, an individual application might be able to partition its activities in a way that allows it to direct queries to multiple resolvers.

### Analysis of client-based selection

This is a simple and effective strategy, but while it provides distribution of DNS queries in the aggregate, it does little to divide information about a particular client between resolvers. It effectively only reduces the number of clients that each resolver can acquire information about. This provides systemic benefit, but does not provide individual clients with any significant advantage as there is still some resolver service that has a complete view of the user's DNS usage patterns.

In addition, there are specific issues where this selection method is used in particular deployment modes. Where different applications make independent resolver selections, activities that involve multiple applications can result in information about those activities being exposed to multiple resolvers.  For instance, an application could open another application for the purposes of handling a specific file type or to load a URL.  This could expose queries related to the activity as a whole to multiple resolvers.

Making different selections at the level of a device resolves this issue. But of course it is still possible that an individual who uses multiple devices might perform similar activities on those devices, but have DNS queries distributed to different resolvers, resulting in replicating that individual's information to multiple resolvers. The individual may or may not be identifiable through fingerprinting of the specific set of queries being made from the devices.

### Enhancements to client-based selection {#discontinuous}

Clients can break continuity of records by occasionally resetting state so that a different resolver is selected.  A client might choose to do this when it moves to a new network location, and may otherwise appear as a new client its current resolver. But it is unclear if there's a sufficient advantage to breaking continuity, as the potential benefits are offset by the client's information being disclosed to several resolvers as part of performing a series of resets. And it is possible that a particular individual's usage patterns can be identified across network locations and periods of using other resolvers.

Breaking continuity is less effective if any state, in particular cached results, is retained across the change.  If activities that depend on DNS querying are continued across the change then it might be possible for the old resolver to make inferences about the activity on the new resolver, or the new resolver to make similar guesses about past activity.  As many modern applications provide session continuity features across shutdowns and crashes, this can mean that finding an appropriate point in time to perform a switch can be difficult.

## Name-based {#namebased}

Clients might also additionally attempt to distribute queries based on the name being queried.  This results in different names going to different resolvers.

A naïve algorithm for name distribution uses the target name as input to a fixed hash:

    i = h(queried name) % n

However, this simplistic approach fails to prevent related queries from being distributed to different resolvers in several ways.  For instance, queries that are executed after receiving a CNAME record in a response will leak the same information as the original query that resulted in the CNAME record.  Services that use related domain names -- such as where "example.com" uses "static.example.com" or "cdn.example.net" -- might reveal the use of the combined service to a resolver that receives a query for any associated name.  In both cases, sensitive information is effectively replicated across multiple resolvers.

### Name reduction

In order to reduce the effect of distributing similar names to different servers, a grouping mechanism might be used.  Leading labels in names might be erased before being input to the hashing algorithm.  This requires that the part of the suffix that is shared between different services can be identified.  For the purposes of ensuring that queries are consistently routed to the same resolver, a weak signal is likely sufficient.

Several options for grouping domain names into equivalence sets might be used:

* The [public suffix list](https://publicsuffix.org/) provides a manually curated list of shared domain suffixes.  Names can be reduced to include one label more than the list allows, referred to as effective top-level domain plus one (eTLD+1).  This reduces the number of cases where queries for domains under the same administrative control are sent to different resolvers.

* Services often relies on multiple domain names across different eTLD+1 domains.  Developing equivalence sets might be needed to avoid broadcasting queries to servers.  Mozilla maintains a manually curated [equivalence list](https://github.com/mozilla-services/shavar-prod-lists/blob/master/disconnect-entitylist.json) for web sites that aims to maps the complete set of unrelated names used by services to a single service name.

* Other technologies, such as the proposed [first party sets](https://github.com/krgovind/first-party-sets) or the abandoned DBOUND {{?DBOUND=I-D.levine-dbound-dns}} provide domain owners a means to declare some form of equivalence for different names.

Each of these techniques are imperfect in different ways. They may also skew the distribution of queries in ways that might concentrate information on particular resolvers.

# Early conclusions {#conclusions}

## Analysis conclusions

Both the client-based and more advanced name-based strategies provide benefits. The former provides primarily a systemic benefit, while the latter provides also some privacy benefits to each individual client. However, neither strategy is perfect, and can leak the same information to multiple resolvers in some cases.

## Recommendations

Both strategies are, however, likely generally beneficial in the common cases, and can improve the overall privacy situation. And they are certainly a considerable privacy improvement over a situation where a large number of clients use a single resolver.

Their use may also reduce any pressures against specific resolvers, as information available in these specific resolvers does not constitute all information about all clients. As such, the use of one of these distribution strategies is tentatively recommended, subject to further testing, discussion, and resolving any remaining operational issues.

The naive name-based strategy is, however, not recommended, and neither are other, even simpler strategies listed in {{bad-algorithms}}. It should be noted that no technique presented in this memo can defend against a situation where an actor such as a surveillance agency has access to information from all resolvers.

## Poor distribution strategies {#bad-algorithms}

Random allocation to a resolver might be implemented:

    i = rand() % n

Similar drawbacks can be seen where clients iterate over available resolvers:

    i = counter++ % n

Whether this choice is made on a per-query basis, these two methods eventually provide information about all queries to all resolvers over time.  Domain names are often queried many times over long periods, so queries for the same domain name will eventually be distributed to all resolvers.  Only one-off queries will avoid being distributed.

Implementing either method at a much slower cadence might be effective, subject to the constraints in {{discontinuous}}.  This only slows the distribution of information about repeated queries to all resolvers.

# Effects of query distribution {#effects}

Choosing to use more than one DNS resolver has broader implications than just the effect on privacy.  Using multiple resolvers is a significant change from the assumed model where stub resolvers send all queries to a single resolver.

## Caching considerations {#caching}

Using a common cache for multiple resolvers introduces the possibility that a resolver could learn about queries that were originally directed to another resolvers by observing the absence of queries.  Though this can reduce caching performance, clients can address this by having a per-resolver cache and only using the cache for the selected resolver.

## Consistency considerations

Making the same query to multiple resolvers can result in different answers.  For instance, DNS-based load balancing can lead to different answers being produced over time or for different query origins.  Or, different resolvers might have different policies with respect to blocking or filtering of queries that lead to clients receiving inconsistent answers.

In the extreme, an application might encounter errors as a result of receiving incompatible answers, particularly if a server operator (incorrectly) assumes that different DNS queries for the same client always originate from the same source address.  This is most likely to occur if name-based selection is used, as queries could be related based on information that the client does not consider.

## Resolver load distribution and failover

Any selection of resolvers that is based on random inputs will need to account for available capacity on resolvers.  Otherwise, resolvers with less available query-processing capacity will receive too high a proportion of all queries.  Clients only need to be informed of relative available capacity in order to make an appropriate selection.  How relative capacities of resolvers are determined is not in scope for this document.

The choice of different resolvers would also need to work well with whatever mechanisms exist for failover to alternate resolvers when one is not responsive. The same is true of IPv4/IPv6 connectivity, the availability of communications to specific ports, etc. And the dynamic situation should obviously not lead to extensive leakage to different resolvers, either.

## Query performance

Distribution of queries between resolvers also means that clients are exposed to greater variations in performance.

## Debugging

The use of multiple resolvers may complicate debugging.

# Further work {#furtherwork}

Should there be interest in the deployment of ideas laid out in this memo, further work is needed. There would have to be ways to configure systems to use multiple resolvers, including for instance:

* Central configuration mechanisms to enable the use of multiple resolvers, perhaps through usual network configuration mechanisms or choices made by applications using resolver services directly. It may also be necessary to employ discovery mechanisms, such as, e.g., {{I-D.schinazi-httpbis-doh-preference-hints}}  (but see {{goals}}).

* Mechanisms to allow both failover to working resolvers when a resolver is unreachable,

* Additional testing for potential operational issues discussed in {{opscontext}} would be beneficial.

Finally, more work is needed to determine factors other than privacy that could motivate having queries routed to the same resolver. The choice between different approaches is often a combination of several factors, and privacy is only one of those factors.

--- back

# Acknowledgements {#ack}

The authors would like to thank Christian Huitema, Ari Keränen, Mark Nottingham, Stephen Farrell, Gonzalo Camarillo, Mirja Kühlewind, David Allan, Daniel Migault Goran AP Eriksson, and many others for interesting discussions in this problem space.
