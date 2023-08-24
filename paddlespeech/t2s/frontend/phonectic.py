# Copyright (c) 2020 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from abc import ABC
from abc import abstractmethod
from typing import List

import numpy as np
import paddle
from g2p_en import G2p
from g2pM import G2pM

from paddlespeech.t2s.frontend.normalizer.normalizer import normalize
from paddlespeech.t2s.frontend.punctuation import get_punctuations
from paddlespeech.t2s.frontend.vocab import Vocab
from paddlespeech.t2s.frontend.zh_normalization.text_normlization import TextNormalizer

# discard opencc untill we find an easy solution to install it on windows
# from opencc import OpenCC

__all__ = ["Phonetics", "English", "EnglishCharacter", "Chinese", 'Thai']


class Phonetics(ABC):
    @abstractmethod
    def __call__(self, sentence):
        pass

    @abstractmethod
    def phoneticize(self, sentence):
        pass

    @abstractmethod
    def numericalize(self, phonemes):
        pass


class English(Phonetics):
    """ Normalize the input text sequence and convert into pronunciation id sequence.

    https://github.com/Kyubyong/g2p/blob/master/g2p_en/g2p.py

    phonemes = ["<pad>", "<unk>", "<s>", "</s>"] + [   
        'AA0', 'AA1', 'AA2', 'AE0', 'AE1', 'AE2', 'AH0', 'AH1', 'AH2', 'AO0',
        'AO1', 'AO2', 'AW0', 'AW1', 'AW2', 'AY0', 'AY1', 'AY2', 'B', 'CH', 'D', 'DH',
        'EH0', 'EH1', 'EH2', 'ER0', 'ER1', 'ER2', 'EY0', 'EY1',
        'EY2', 'F', 'G', 'HH',
        'IH0', 'IH1', 'IH2', 'IY0', 'IY1', 'IY2', 'JH', 'K', 'L',
        'M', 'N', 'NG', 'OW0', 'OW1',
        'OW2', 'OY0', 'OY1', 'OY2', 'P', 'R', 'S', 'SH', 'T', 'TH',
        'UH0', 'UH1', 'UH2', 'UW',
        'UW0', 'UW1', 'UW2', 'V', 'W', 'Y', 'Z', 'ZH']
    """

    LEXICON = {
        # key using lowercase
        "AI".lower(): [["EY0", "AY1"]],
    }

    def __init__(self, phone_vocab_path=None):
        self.backend = G2p()
        self.backend.cmu.update(English.LEXICON)
        self.phonemes = list(self.backend.phonemes)
        self.punctuations = get_punctuations("en")
        self.vocab = Vocab(self.phonemes + self.punctuations)
        self.vocab_phones = {}
        self.punc = "、：，；。？！“”‘’':,;.?!"
        self.text_normalizer = TextNormalizer()
        if phone_vocab_path:
            with open(phone_vocab_path, 'rt', encoding='utf-8') as f:
                phn_id = [line.strip().split() for line in f.readlines()]
            for phn, id in phn_id:
                self.vocab_phones[phn] = int(id)

    def phoneticize(self, sentence):
        """ Normalize the input text sequence and convert it into pronunciation sequence.
        Args:
            sentence (str): The input text sequence.
        Returns: 
            List[str]: The list of pronunciation sequence.
        """
        start = self.vocab.start_symbol
        end = self.vocab.end_symbol
        phonemes = ([] if start is None else [start]) \
                   + self.backend(sentence) \
                   + ([] if end is None else [end])
        phonemes = [item for item in phonemes if item in self.vocab.stoi]
        return phonemes

    def _p2id(self, phonemes: List[str]) -> np.array:
        phone_ids = [self.vocab_phones[item] for item in phonemes]
        return np.array(phone_ids, np.int64)

    def get_input_ids(self,
                      sentence: str,
                      merge_sentences: bool=False,
                      to_tensor: bool=True) -> paddle.Tensor:
        sentences = self.text_normalizer._split(sentence, lang="en")

        phones_list = []
        temp_phone_ids = []
        for sentence in sentences:
            #print(sentence)
            phones = self.phoneticize(sentence)
            #print(phones)
            # remove start_symbol and end_symbol
            phones = phones[1:-1]
            phones = [phn for phn in phones if not phn.isspace()]
            # replace unk phone with sp
            phones = [
                phn
                if (phn in self.vocab_phones and phn not in self.punc) else "sp"
                for phn in phones
            ]
            if len(phones) != 0:
                phones_list.append(phones)

        if merge_sentences:
            merge_list = sum(phones_list, [])
            # rm the last 'sp' to avoid the noise at the end
            # cause in the training data, no 'sp' in the end
            if merge_list[-1] == 'sp':
                merge_list = merge_list[:-1]
            phones_list = []
            phones_list.append(merge_list)

        for part_phones_list in phones_list:
            phone_ids = self._p2id(part_phones_list)
            if to_tensor:
                phone_ids = paddle.to_tensor(phone_ids)
            temp_phone_ids.append(phone_ids)

        result = {}
        result["phone_ids"] = temp_phone_ids
        return result

    def numericalize(self, phonemes):
        """ Convert pronunciation sequence into pronunciation id sequence.
        Args:
            phonemes (List[str]): The list of pronunciation sequence.
        Returns: 
            List[int]: The list of pronunciation id sequence.
        """
        ids = [
            self.vocab.lookup(item) for item in phonemes
            if item in self.vocab.stoi
        ]
        return ids

    def reverse(self, ids):
        """ Reverse the list of pronunciation id sequence to a list of pronunciation sequence.
        Args:
            ids (List[int]): The list of pronunciation id sequence.
        Returns: 
            List[str]: The list of pronunciation sequence.
        """
        return [self.vocab.reverse(i) for i in ids]

    def __call__(self, sentence):
        """ Convert the input text sequence into pronunciation id sequence.
        Args:
            sentence(str): The input text sequence.
        Returns: 
            List[str]: The list of pronunciation id sequence.
        """
        return self.numericalize(self.phoneticize(sentence))

    @property
    def vocab_size(self):
        """ Vocab size.
        """
        return len(self.vocab)


class EnglishCharacter(Phonetics):
    """ Normalize the input text sequence and convert it into character id sequence.
    """

    def __init__(self):
        self.backend = G2p()
        self.graphemes = list(self.backend.graphemes)
        self.punctuations = get_punctuations("en")
        self.vocab = Vocab(self.graphemes + self.punctuations)

    def phoneticize(self, sentence):
        """ Normalize the input text sequence.
        Args:
            sentence(str): The input text sequence.
        Returns:
            str: A text sequence after normalize.
        """
        words = normalize(sentence)
        return words

    def numericalize(self, sentence):
        """ Convert a text sequence into ids.
        Args:
            sentence (str): The input text sequence.
        Returns:
            List[int]:
                List of a character id sequence.
        """
        ids = [
            self.vocab.lookup(item) for item in sentence
            if item in self.vocab.stoi
        ]
        return ids

    def reverse(self, ids):
        """ Convert a character id sequence into text.
        Args:
            ids (List[int]): List of a character id sequence.
        Returns:
            str: The input text sequence.
        """
        return [self.vocab.reverse(i) for i in ids]

    def __call__(self, sentence):
        """ Normalize the input text sequence and convert it into character id sequence.
        Args:
            sentence (str): The input text sequence.
        Returns: 
            List[int]: List of a character id sequence.
        """
        return self.numericalize(self.phoneticize(sentence))

    @property
    def vocab_size(self):
        """ Vocab size.
        """
        return len(self.vocab)


class Chinese(Phonetics):
    """Normalize Chinese text sequence and convert it into ids.
    """

    def __init__(self):
        # self.opencc_backend = OpenCC('t2s.json')
        self.backend = G2pM()
        self.phonemes = self._get_all_syllables()
        self.punctuations = get_punctuations("cn")
        self.vocab = Vocab(self.phonemes + self.punctuations)

    def _get_all_syllables(self):
        all_syllables = set([
            syllable for k, v in self.backend.cedict.items() for syllable in v
        ])
        return list(all_syllables)

    def phoneticize(self, sentence):
        """ Normalize the input text sequence and convert it into pronunciation sequence.
        Args:
            sentence(str): The input text sequence.
        Returns: 
            List[str]: The list of pronunciation sequence.
        """
        # simplified = self.opencc_backend.convert(sentence)
        simplified = sentence
        phonemes = self.backend(simplified)
        start = self.vocab.start_symbol
        end = self.vocab.end_symbol
        phonemes = ([] if start is None else [start]) \
                   + phonemes \
                   + ([] if end is None else [end])
        return self._filter_symbols(phonemes)

    def _filter_symbols(self, phonemes):
        cleaned_phonemes = []
        for item in phonemes:
            if item in self.vocab.stoi:
                cleaned_phonemes.append(item)
            else:
                for char in item:
                    if char in self.vocab.stoi:
                        cleaned_phonemes.append(char)
        return cleaned_phonemes

    def numericalize(self, phonemes):
        """ Convert pronunciation sequence into pronunciation id sequence.
        Args:
            phonemes(List[str]): The list of pronunciation sequence.
        Returns:
                List[int]: The list of pronunciation id sequence.
        """
        ids = [self.vocab.lookup(item) for item in phonemes]
        return ids

    def __call__(self, sentence):
        """ Convert the input text sequence into pronunciation id sequence.
        Args:
            sentence (str): The input text sequence.
        Returns:
            List[str]: The list of pronunciation id sequence.
        """
        return self.numericalize(self.phoneticize(sentence))

    @property
    def vocab_size(self):
        """ Vocab size.
        """
        return len(self.vocab)

    def reverse(self, ids):
        """ Reverse the list of pronunciation id sequence to a list of pronunciation sequence.
        Args:
        ids (List[int]): The list of pronunciation id sequence.
        Returns: 
            List[str]: The list of pronunciation sequence.
        """
        return [self.vocab.reverse(i) for i in ids]


from pythainlp.transliterate import transliterate
#aa = transliterate("แมว")  # output: 'mɛːw'
#print(aa)

class ThaiG2p():
    
    def __init__(self):
        self.phonemes = [

        ]
        pass


    def __call__(self,text):
        return transliterate(text)
    

class Thai(Phonetics):

    LEXICON = {
        # key using lowercase
    }

    def _get_all_syllables(self,phone_vocab_path):
        all_syllables = set()
        with open(phone_vocab_path) as f:
            lines = f.readlines() 
            for l in lines:
                p = l.split(" ")[0]
                all_syllables.add(p)

        return list(all_syllables)
    


    def __init__(self, phone_vocab_path=None):
        self.backend = ThaiG2p()
        #self.backend.cmu.update(English.LEXICON)
        self.phonemes = list(self._get_all_syllables(phone_vocab_path))
        self.punctuations = get_punctuations("en")
        self.vocab = Vocab(self.phonemes + self.punctuations)
        #self.vocab = Vocab( self.punctuations)
        print(self.vocab)
        self.vocab_phones = {}
        self.punc = "、：，；。？！“”‘’':,;.?!"
        self.text_normalizer = TextNormalizer()
        if phone_vocab_path:
            with open(phone_vocab_path, 'rt', encoding='utf-8') as f:
                phn_id = [line.strip().split() for line in f.readlines()]
            for phn, id in phn_id:
                self.vocab_phones[phn] = int(id)

    def phoneticize(self, sentence):
        """ Normalize the input text sequence and convert it into pronunciation sequence.
        Args:
            sentence (str): The input text sequence.
        Returns: 
            List[str]: The list of pronunciation sequence.
        """
        start = self.vocab.start_symbol
        end = self.vocab.end_symbol
        s = self.backend(sentence)
        s = s.replace("ː ","ː")
        print(s)
        #print(s.strip().split(" "))
        #s = "tɕʰ iː˦˥ s a˨˩ n a˦˥ n ʔ a˨˩ r ɔ˨˩ j d oː˧ j tɕʰ a˨˩ pʰ ɔ˦˥ ʔ j aː˨˩ ŋ j i˥˩ ŋ m ɯa˥˩ m aː˧ pʰ r ɔː˦˥ m k a˨˩ p̚ kʰ a˨˩ n o˩˩˦ m p a˧ ŋ s ɛː˩˩˦ n ʔ a˨˩ r ɔ˨˩ j k r ɔː˨˩ p̚"
        phonemes = ([] if start is None else [start]) \
                   + s.strip().split(" ") \
                   + ([] if end is None else [end])
        #phonemes = [item for item in phonemes if item in self.vocab.stoi]
        return phonemes

    def _p2id(self, phonemes: List[str]) -> np.array:
        phone_ids = [self.vocab_phones[item] for item in phonemes]
        return np.array(phone_ids, np.int64)

    def get_input_ids(self,
                      sentence: str,
                      merge_sentences: bool=False,
                      to_tensor: bool=True) -> paddle.Tensor:
        sentences = self.text_normalizer._split(sentence, lang="en")

        phones_list = []
        temp_phone_ids = []
        for sentence in sentences:
            print(sentence)
            phones = self.phoneticize(sentence)
            print(phones)
            # remove start_symbol and end_symbol
            phones = phones[1:-1]
            phones = [phn for phn in phones if not phn.isspace()]
            # replace unk phone with sp
            phones = [
                phn
                if (phn in self.vocab_phones and phn not in self.punc) else "sp"
                for phn in phones
            ]
            if len(phones) != 0:
                phones_list.append(phones)

        if merge_sentences:
            merge_list = sum(phones_list, [])
            # rm the last 'sp' to avoid the noise at the end
            # cause in the training data, no 'sp' in the end
            if merge_list[-1] == 'sp':
                merge_list = merge_list[:-1]
            phones_list = []
            phones_list.append(merge_list)

        for part_phones_list in phones_list:
            print(part_phones_list)
            phone_ids = self._p2id(part_phones_list)
            print(phone_ids)
            if to_tensor:
                phone_ids = paddle.to_tensor(phone_ids)
            temp_phone_ids.append(phone_ids)

        result = {}
        result["phone_ids"] = temp_phone_ids

        return result

    def numericalize(self, phonemes):
        """ Convert pronunciation sequence into pronunciation id sequence.
        Args:
            phonemes (List[str]): The list of pronunciation sequence.
        Returns: 
            List[int]: The list of pronunciation id sequence.
        """
        ids = [
            self.vocab.lookup(item) for item in phonemes
            if item in self.vocab.stoi
        ]
        return ids

    def reverse(self, ids):
        """ Reverse the list of pronunciation id sequence to a list of pronunciation sequence.
        Args:
            ids (List[int]): The list of pronunciation id sequence.
        Returns: 
            List[str]: The list of pronunciation sequence.
        """
        return [self.vocab.reverse(i) for i in ids]

    def __call__(self, sentence):
        """ Convert the input text sequence into pronunciation id sequence.
        Args:
            sentence(str): The input text sequence.
        Returns: 
            List[str]: The list of pronunciation id sequence.
        """
        return self.numericalize(self.phoneticize(sentence))

    @property
    def vocab_size(self):
        """ Vocab size.
        """
        return len(self.vocab)

