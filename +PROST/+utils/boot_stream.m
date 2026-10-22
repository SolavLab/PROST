function stream = boot_stream(seed, b)
%BOOT_STREAM random stream of bootstrap replicate B. Every replicate uses its own
% substream of one seeded generator, so replicate B draws the same sample on
% whichever parfor worker runs it, and the whole bootstrap is reproducible from
% SEED.
% Input :
%   seed - seed of the generator.
%   b - replicate number, used as the substream index.
% Output :
%   stream - a Threefry RandStream set to substream B.
% Example usage :
%   stream = PROST.utils.boot_stream(20261006, 1)

    stream = RandStream('Threefry', 'Seed', seed);
    stream.Substream = b;
end
