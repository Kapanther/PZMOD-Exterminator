local group = AttachedLocations.getGroup("Human")

group:getOrCreateLocation("OnMiningHelmetHeadLight"):setAttachmentName("on_mining_helmet_middle")
group:getOrCreateLocation("OnMiningHelmetTorchSmall"):setAttachmentName("on_mining_helmet_low_right_torch")
group:getOrCreateLocation("OnMiningHelmetHandTorchBig"):setAttachmentName("on_mining_helmet_low_right")
group:getOrCreateLocation("OnMiningHelmetHandTorchSmall"):setAttachmentName("on_mining_helmet_right")
group:getOrCreateLocation("OnMiningHelmetTorch"):setAttachmentName("on_mining_helmet_left")

--Taken from better flashlights mod.. thank you!