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
  RFC1035: 
  RFC7258: 
  RFC8446:
  RFC8484:
  I-D.ietf-tls-esni:
  I-D.ietf-quic-transport:
  
--- abstract

This memo discusses the use of a set of different DNS resolvers to reduce privacy problems related to resolvers learning the Internet usage patterns of their clients.

--- middle

# Introduction {#introduction}

When a DNS client {{RFC1035}} uses a resolver service, that service learns information about the client's usage patterns, such as the applications the user is using, what web sites are visited, and so on. While Internet communications are increasingly protected by encrypting both content and control information {{RFC8446}}, {{RFC8484}}, {{I-D.ietf-quic-transport}}, {{I-D.ietf-tls-esni}}, the DNS resolver service becomes aware of the specific domains being queried, and is typically also aware of which client made the query.

Leaking this information to the Internet infrastructure component such as a DNS resolver service can be problematic when the service is not entirely trusted. And even when  the service is trusted and well maintained, legal and commercial pressures or surveillance activity may result in some of the information given to the service to be misused, particularly when a service holds information for a large number of users. This is not desirable.

Defending against privacy leaks for DNS queries is particularly important given the prevalence of pervasive surveillance efforts {{RFC7258}}.

This memo discusses the use of a set of different DNS resolvers to reduce privacy problems related to DNS resolvers. The architectural principle followed here is one of attempting to avoid high-value targets and the concentration of any individual users's information in one place. We outline a number of different strategies for distributing queries to the different resolvers and analyze the privacy and other impacts of those strategies. Our observation is that a simplistic models -- such as a round-robin algorithm -- are not necessarily the best suited for this task.

The focus of this document is precisely only the choice of a resolver from a known set. There are many other worthwhile topics in the general space of providing better confidentiality or privacy for DNS queries, or for operating encrypted DNS query services. Topics such as resolver discovery, operational practices at any individial resolver service, etc. are outside the scope of this memo.

The rest of this memo is organized as follows. {{goals}} specifies the requirements that we would like such a distribution arrangement to provide. {{algorithms}} discusses the different strategies, and makes some early recommendations among the strategies. {{furtherwork}} discusses potential further work in this area.

# Goals {#goals}

There are many possible goals for building distributed services, with the most typical one being the ability to scale to be able to serve large number of clients. This memo is not focused on this aspect, but rather looks at distributing queries to different resolver service providers to provided what privacy benefits.

The question is how to reduce information learned by any individual resolver service provider through distribution of queries from different clients. Note that such individual resolver service providers themselves may in turn be distributed in other ways (e.g., through use of anycast or other scaling techniques).

Some of the basic goals that this distribution should achive include:

* Not concentrating information from all clients to a single resolver service.

* Reducing the information given out regarding a single client to any individual resolver service.

The latter goal can be broken further down to:

* Avoiding sending queries about the same destination to different services, as otherwise the result is worse than not doing any distribution at all: all the different services will eventually get the same information about a particular client.

* Avoiding sending queries about related destinations (*.example.com) to different services, as otherwise the different services will likely conclude that the client is using the "example.com" service anyway, regardless of the individual sub-domains accessed on specific requests.

* For browsers, avoiding sending queries about destinations on the same page (https://example.com pulls an image from https://anotherexample.com) to different servers. This is because there is a possibility of correlation that  lets someone determine that the user was on that page.

* Otherwise, sending queries about different things to different servers, to keep each server aware of minimal information about a particular client.

Some of these goals depend on which component in a system is performing the queries. The web page goal above can only be done by browsers, whereas the other rules could also be implemented in an OS-based resolver client.

# Potential selection algorithms {#algorithms}

This section introduces and analyzes several potential strategies for distributing queries to different resolvers. Each strategy is formulated as an algorithm for choosing a resolver Ri from a set of n resolvers R1, R2, ...,  Rn.

Note that the list of algorithms may grow in a future version of this memo; this set is the initially analyzed set.

## Client-based {#clientbased}

The simplest algorithm is to distribute each different client to a different resolver. This reduces the number of users any particular service will know about. However, in order to function properly, this methods needs to apply some kind of stable assignment mechanism, e.g., a stable hash.

One way of doing this is to hash the client's identity in some manner:

    i = h(client identity) % n

While this satisfies the first overall goal in {{goals}}, it does nothing about splitting information regarding a particular client to different services.

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

The authors would like to thank Christian Huitema, Ari Keranen, Mark Nottingham, Stephen Farrell, Gonzalo Camarillo, Mirja Kuhlewind and many others for interesting discussions in this problem space.
