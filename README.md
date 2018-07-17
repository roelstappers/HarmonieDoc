# Harmonie

Create graph of ecflow tasks and file dependencies in the Harmonie scripting system for data assimilation. 

Needs graphviz:

```bash
sudo apt install graphviz
```

To make a graph  with hrefs to hirlam.org wiki (will produces harmonie.svg in the svg directory):

```bash
make
```

To make the graph with hrefs pointing to scripts

```bash
make trac
```

To run the test. 
```bash
make test
```
This checks ecflow tasks with missing tooltips and/or hrefs.
hrefs are also validated if a valid ~/.netrc file for hirlam.org is available. 

