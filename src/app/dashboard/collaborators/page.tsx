"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Users,
  Search,
  Filter,
  MapPin,
  Briefcase,
  Star,
  MessageSquare,
  UserPlus,
  CheckCircle2
} from "lucide-react";
import { useAuth } from "@/contexts/auth-context";
import { cn } from "@/lib/utils";

interface Collaborator {
  id: string;
  name: string;
  avatar?: string;
  title: string;
  location: string;
  skills: string[];
  rating: number;
  projects: number;
  bio: string;
  available: boolean;
  connected: boolean;
}

export default function CollaboratorsPage() {
  const { user } = useAuth();
  const [collaborators, setCollaborators] = useState<Collaborator[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedSkills, setSelectedSkills] = useState<string[]>([]);
  const [showFilters, setShowFilters] = useState(false);

  useEffect(() => {
    const mockCollaborators: Collaborator[] = [
      {
        id: "1",
        name: "Alex Johnson",
        title: "Video Editor & Motion Graphics Designer",
        location: "San Francisco, CA",
        skills: ["Video Editing", "After Effects", "Premiere Pro", "Motion Graphics"],
        rating: 4.8,
        projects: 24,
        bio: "Experienced video editor with 5+ years creating engaging content for brands and creators.",
        available: true,
        connected: false,
      },
      {
        id: "2",
        name: "Sarah Chen",
        title: "Music Producer & Sound Designer",
        location: "Los Angeles, CA",
        skills: ["Music Production", "Sound Design", "Mixing", "Mastering"],
        rating: 4.9,
        projects: 31,
        bio: "Award-winning music producer specializing in cinematic and commercial soundtracks.",
        available: true,
        connected: true,
      },
      {
        id: "3",
        name: "Michael Rodriguez",
        title: "3D Artist & VFX Specialist",
        location: "New York, NY",
        skills: ["3D Modeling", "VFX", "Blender", "Cinema 4D"],
        rating: 4.7,
        projects: 18,
        bio: "Creative 3D artist passionate about bringing ideas to life through visual effects.",
        available: false,
        connected: false,
      },
      {
        id: "4",
        name: "Emily Watson",
        title: "Content Strategist & Social Media Manager",
        location: "Austin, TX",
        skills: ["Content Strategy", "Social Media", "Marketing", "Analytics"],
        rating: 4.6,
        projects: 42,
        bio: "Strategic content creator helping brands grow their online presence.",
        available: true,
        connected: false,
      },
    ];
    setCollaborators(mockCollaborators);
  }, []);

  const allSkills = Array.from(
    new Set(collaborators.flatMap((c) => c.skills))
  ).sort();

  const filteredCollaborators = collaborators.filter((collab) => {
    const matchesSearch =
      collab.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      collab.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      collab.skills.some((skill) =>
        skill.toLowerCase().includes(searchQuery.toLowerCase())
      );

    const matchesSkills =
      selectedSkills.length === 0 ||
      selectedSkills.some((skill) => collab.skills.includes(skill));

    return matchesSearch && matchesSkills;
  });

  const handleConnect = (collaboratorId: string) => {
    setCollaborators((prev) =>
      prev.map((collab) =>
        collab.id === collaboratorId
          ? { ...collab, connected: !collab.connected }
          : collab
      )
    );
  };

  return (
    <div className="container mx-auto p-6 max-w-7xl">
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-3xl font-bold mb-2">Find Collaborators</h1>
            <p className="text-muted-foreground">
              Connect with talented creators and build amazing projects together
            </p>
          </div>
          <Button
            variant="outline"
            onClick={() => setShowFilters(!showFilters)}
          >
            <Filter className="h-4 w-4 mr-2" />
            Filters
          </Button>
        </div>

        <div className="flex gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search by name, skills, or expertise..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9"
            />
          </div>
        </div>

        {showFilters && (
          <Card className="mt-4">
            <CardHeader>
              <CardTitle>Filter by Skills</CardTitle>
              <CardDescription>
                Select skills to find collaborators with specific expertise
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                {allSkills.map((skill) => (
                  <Badge
                    key={skill}
                    variant={
                      selectedSkills.includes(skill) ? "default" : "outline"
                    }
                    className="cursor-pointer"
                    onClick={() => {
                      setSelectedSkills((prev) =>
                        prev.includes(skill)
                          ? prev.filter((s) => s !== skill)
                          : [...prev, skill]
                      );
                    }}
                  >
                    {skill}
                  </Badge>
                ))}
              </div>
              {selectedSkills.length > 0 && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="mt-4"
                  onClick={() => setSelectedSkills([])}
                >
                  Clear filters
                </Button>
              )}
            </CardContent>
          </Card>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredCollaborators.length === 0 ? (
          <div className="col-span-full text-center py-12">
            <Users className="h-16 w-16 mx-auto mb-4 text-muted-foreground opacity-50" />
            <h3 className="text-lg font-semibold mb-2">No collaborators found</h3>
            <p className="text-muted-foreground">
              Try adjusting your search or filters
            </p>
          </div>
        ) : (
          filteredCollaborators.map((collaborator) => (
            <Card key={collaborator.id} className="flex flex-col">
              <CardHeader>
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <Avatar className="h-12 w-12">
                      <AvatarImage src={collaborator.avatar} />
                      <AvatarFallback>
                        {collaborator.name.charAt(0)}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex-1 min-w-0">
                      <CardTitle className="text-lg truncate">
                        {collaborator.name}
                      </CardTitle>
                      <div className="flex items-center gap-1 mt-1">
                        <Star className="h-3 w-3 fill-yellow-500 text-yellow-500" />
                        <span className="text-sm font-medium">
                          {collaborator.rating}
                        </span>
                        <span className="text-xs text-muted-foreground">
                          ({collaborator.projects} projects)
                        </span>
                      </div>
                    </div>
                  </div>
                  {collaborator.available && (
                    <Badge variant="outline" className="bg-green-500/10 text-green-600 border-green-500/20">
                      Available
                    </Badge>
                  )}
                </div>
                <CardDescription className="flex items-center gap-2">
                  <Briefcase className="h-3 w-3" />
                  <span className="truncate">{collaborator.title}</span>
                </CardDescription>
                <CardDescription className="flex items-center gap-2">
                  <MapPin className="h-3 w-3" />
                  {collaborator.location}
                </CardDescription>
              </CardHeader>
              <CardContent className="flex-1 flex flex-col">
                <p className="text-sm text-muted-foreground mb-4 line-clamp-3">
                  {collaborator.bio}
                </p>
                <div className="flex flex-wrap gap-2 mb-4">
                  {collaborator.skills.slice(0, 3).map((skill) => (
                    <Badge key={skill} variant="secondary" className="text-xs">
                      {skill}
                    </Badge>
                  ))}
                  {collaborator.skills.length > 3 && (
                    <Badge variant="secondary" className="text-xs">
                      +{collaborator.skills.length - 3} more
                    </Badge>
                  )}
                </div>
                <div className="flex gap-2 mt-auto">
                  <Button
                    variant={collaborator.connected ? "outline" : "default"}
                    className="flex-1"
                    onClick={() => handleConnect(collaborator.id)}
                  >
                    {collaborator.connected ? (
                      <>
                        <CheckCircle2 className="h-4 w-4 mr-2" />
                        Connected
                      </>
                    ) : (
                      <>
                        <UserPlus className="h-4 w-4 mr-2" />
                        Connect
                      </>
                    )}
                  </Button>
                  <Button variant="outline" size="icon">
                    <MessageSquare className="h-4 w-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>
    </div>
  );
}

