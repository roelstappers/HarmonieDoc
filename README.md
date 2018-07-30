# Harmonie

Create graph of ecflow tasks and file dependencies in the Harmonie scripting system for data assimilation. 

Needs graphviz:

```bash
sudo apt install graphviz
```

To make a graph  with hrefs to hirlam.org wiki and github (produces harmonie.svg in the svg directory):

```bash
make
```

In the graph a red wiki block indicates a missing href to hirlam.org wiki.  


To run the test. 
```bash
make test
```
This checks ecflow tasks with missing tooltips and/or hrefs.
hrefs are also validated if a valid ~/.netrc file for hirlam.org is available. 

