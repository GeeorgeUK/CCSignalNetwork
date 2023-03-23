ZoneRegistry = {}
ZoneRegistry.all = {
  "malachite", "lukredes", "shortlands"
}

ZoneRegistry.malachite = {}
ZoneRegistry.malachite.id = 1
ZoneRegistry.malachite.platforms = {"1","2","3","4"}
ZoneRegistry.malachite.directions = {"north", "south"}
ZoneRegistry.malachite.platform = {}
ZoneRegistry.malachite.platform["1"] = {
  id = 1,
  north = {
    id = 1,
    -- Which zone identifiers can we reach? Format is X.Y.Z:
    -- X is the ID of the zone
    -- Y is the ID of the platform
    -- Z is the ID of the direction
    canReach = {}
  },
  south = {
    id=2,
    canReach = {"2.1.2", "2.2.2"}
  }
}
ZoneRegistry.malachite.platform["2"] = {
  id = 2,
  north = {
    id = 1,
    canReach = {}
  },
  south = {
    id = 2,
    canReach = {"2.1.2", "2.2.2"}
  }
}
ZoneRegistry.malachite.platform["3"] = {
  id = 3,
  north = {
    id = 1,
    canReach = {}
  },
  south = {
    id = 2,
    canReach = {"2.1.2", "2.2.2"}
  }
}
ZoneRegistry.malachite.platform["4"] = {
  id = 4,
  north = {
    id = 1,
    canReach = {}
  },
  south = {
    id = 2,
    canReach = {"2.1.2", "2.2.2"}
  }
}

ZoneRegistry.lukredes = {}
ZoneRegistry.lukredes.id = 2
ZoneRegistry.lukredes.platforms = {"1", "2"}
ZoneRegistry.lukredes.directions = {"north", "south"}
ZoneRegistry.lukredes.platform = {}
ZoneRegistry.lukredes.platform["1"] = {
  id = 1,
  north = {
    id = 1,
    canReach = {"1.1.1", "1.2.1", "1.3.1", "1.4.1"}
  },
  south = {
    id = 2,
    canReach = {"3.2.2", "3.3.2", "3.5.2"}
  }
}
ZoneRegistry.lukredes.platform["2"] = {
  id = 2,
  north = {
    id = 1,
    canReach = {"1.1.1", "1.2.1", "1.3.1", "1.4.1"}
  },
  south = {
    id = 2,
    canReach = {"3.2.2", "3.3.2", "3.5.2"}
  }
}

ZoneRegistry.shortlands = {}
ZoneRegistry.shortlands.id = 3
ZoneRegistry.shortlands.platforms = {"1", "2", "3", "4", "bypass"}
ZoneRegistry.shortlands.directions = {"north", "south"}
ZoneRegistry.shortlands.platform = {}
ZoneRegistry.shortlands.platform["1"] = {
  id = 1,
  north = {
    id = 1,
    canReach = {}
  },
  south = {
    id = 2,
    canReach = {}
  }
}
ZoneRegistry.shortlands.platform["2"] = {
  id = 2,
  north = {
    id = 1,
    canReach = {"2.1.1", "2.2.1"}
  },
  south = {
    id = 2,
    canReach = {}
  }
}
ZoneRegistry.shortlands.platform["3"] = {
  id = 3,
  north = {
    id = 1,
    canReach = {"2.1.1", "2.2.1"}
  },
  south = {
    id = 2,
    canReach = {}
  }
}
ZoneRegistry.shortlands.platform["4"] = {
  id = 4,
  north = {
    id = 1,
    canReach = {}
  },
  south = {
    id = 2,
    canReach = {}
  }
}
ZoneRegistry.shortlands.platform["bypass"] = {
  id = 5,
  north = {
    id = 1,
    canReach = {"2.1.1", "2.1.2"}
  },
  south = {
    id = 2,
    canReach = {}
  }
}

ZoneRegistry.depot = {}
ZoneRegistry.depot.id = 4
ZoneRegistry.depot.platforms = {"1","2","3","4","5"}
ZoneRegistry.depot.directions = {"inbound","outbound"}
ZoneRegistry.depot.platform = {}
ZoneRegistry.depot.platform["1"] = {
  id = 1,
  inbound = {
    id = 1,
    canReach = {},
  },
  outbound = {
    id = 2,
    canReach = {"3.1.2"}
  }
}
ZoneRegistry.depot.platform["2"] = {
  id = 2,
  inbound = {
    id = 1,
    canReach = {},
  },
  outbound = {
    id = 2,
    canReach = {"3.1.2"}
  }
}
ZoneRegistry.depot.platform["3"] = {
  id = 3,
  inbound = {
    id = 1,
    canReach = {},
  },
  outbound = {
    id = 2,
    canReach = {"3.1.2"}
  }
}
ZoneRegistry.depot.platform["4"] = {
  id = 4,
  inbound = {
    id = 1,
    canReach = {},
  },
  outbound = {
    id = 2,
    canReach = {"3.1.2"}
  }
}
ZoneRegistry.depot.platform["5"] = {
  id = 5,
  inbound = {
    id = 1,
    canReach = {},
  },
  outbound = {
    id = 2,
    canReach = {"3.1.2"}
  }
}